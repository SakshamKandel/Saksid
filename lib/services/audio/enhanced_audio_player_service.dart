import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/models/song_model.dart';
import '../../domain/entities/queue_state.dart';
import '../stream/stream_resolver.dart';
import '../prefetch/prefetch_service.dart';
import '../cache/audio_cache_manager.dart';

/// Enhanced audio player with gapless playback support.
///
/// Features:
/// - ConcatenatingAudioSource for true gapless playback
/// - Rolling URL refresh (10s before next track)
/// - Immutable QueueState as single source of truth
/// - Prefetch integration
/// - Low-latency configuration
class EnhancedAudioPlayerService {
  final AudioPlayer _audioPlayer;
  final StreamResolver _streamResolver;
  final PrefetchService _prefetchService;
  final AudioCacheManager _cacheManager;

  // Single source of truth for queue state
  final BehaviorSubject<QueueState> _queueStateSubject =
      BehaviorSubject.seeded(QueueState.empty);

  // Playback state
  final BehaviorSubject<PlaybackStatus> _playbackStatusSubject =
      BehaviorSubject.seeded(PlaybackStatus.idle);

  // Error stream
  final BehaviorSubject<PlayerError?> _errorSubject =
      BehaviorSubject.seeded(null);

  // Audio source for gapless playback
  ConcatenatingAudioSource? _audioSource;

  // Track URL refresh timer
  Timer? _urlRefreshTimer;

  // Track index mapping (queue index -> audio source index)
  final Map<int, int> _sourceIndexMap = {};

  bool _isDisposed = false;

  EnhancedAudioPlayerService({
    required StreamResolver streamResolver,
    required PrefetchService prefetchService,
    required AudioCacheManager cacheManager,
  })  : _audioPlayer = AudioPlayer(),
        _streamResolver = streamResolver,
        _prefetchService = prefetchService,
        _cacheManager = cacheManager {
    _setupPlayerListeners();
  }

  // ========== Public Streams ==========

  Stream<QueueState> get queueStateStream => _queueStateSubject.stream;
  QueueState get queueState => _queueStateSubject.value;

  Stream<PlaybackStatus> get playbackStatusStream =>
      _playbackStatusSubject.stream;
  PlaybackStatus get playbackStatus => _playbackStatusSubject.value;

  Stream<Duration> get positionStream =>
      _audioPlayer.positionStream.where((p) => p != null).cast<Duration>();
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  Stream<PlayerError?> get errorStream => _errorSubject.stream;

  SongModel? get currentTrack => queueState.currentTrack;
  bool get isPlaying => _audioPlayer.playing;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;

  // ========== Playback Control ==========

  /// Play a single track.
  Future<void> playSong(SongModel track) async {
    await playQueue([track], startIndex: 0);
  }

  /// Play a queue of tracks.
  Future<void> playQueue(List<SongModel> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;

    _updateStatus(PlaybackStatus.loading);

    try {
      // Update queue state
      final newState = queueState.withTracks(tracks, startIndex: startIndex);
      _queueStateSubject.add(newState);

      // Pin current and next track in cache
      _pinCurrentTracks(newState);

      // Update prefetch queue
      _prefetchService.updatePrefetchQueue(tracks, startIndex);

      // Build audio source
      await _buildAudioSource(newState);

      // Seek to start index and play
      if (_audioSource != null && _sourceIndexMap.containsKey(startIndex)) {
        await _audioPlayer.seek(Duration.zero,
            index: _sourceIndexMap[startIndex]);
      }

      await _audioPlayer.play();
      _updateStatus(PlaybackStatus.playing);

      // Start URL refresh timer
      _startUrlRefreshTimer();
    } catch (e, stack) {
      debugPrint('EnhancedAudioPlayer: playQueue failed: $e');
      debugPrint('EnhancedAudioPlayer: Stack: $stack');

      // Check if it's a background audio initialization error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('lateinitializationerror') ||
          errorStr.contains('audiohandler') ||
          errorStr.contains('audioservice')) {
        _handleError(
            'Background audio not available. Please restart the app.', e);
      } else {
        _handleError('Failed to play queue', e);
      }
      _updateStatus(PlaybackStatus.error);
    }
  }

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Play.
  Future<void> play() async {
    await _audioPlayer.play();
    _updateStatus(PlaybackStatus.playing);
  }

  /// Pause.
  Future<void> pause() async {
    await _audioPlayer.pause();
    _updateStatus(PlaybackStatus.paused);
  }

  /// Stop.
  Future<void> stop() async {
    await _audioPlayer.stop();
    _updateStatus(PlaybackStatus.stopped);
    _urlRefreshTimer?.cancel();
  }

  /// Seek to position.
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Skip to next track.
  Future<void> next() async {
    final newState = queueState.toNext();
    if (newState == queueState) return; // No change

    _queueStateSubject.add(newState);
    _pinCurrentTracks(newState);
    _prefetchService.updatePrefetchQueue(
        newState.tracks, newState.currentIndex);

    // If track already in audio source, seek to it
    if (_sourceIndexMap.containsKey(newState.currentIndex)) {
      await _audioPlayer.seek(Duration.zero,
          index: _sourceIndexMap[newState.currentIndex]);
    } else {
      // Need to add track to audio source
      await _addTrackToSource(newState.currentTrack!, newState.currentIndex);
      await _audioPlayer.seek(Duration.zero,
          index: _sourceIndexMap[newState.currentIndex]);
    }
  }

  /// Skip to previous track.
  Future<void> previous() async {
    // If past 3 seconds, restart current track
    if (_audioPlayer.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    final newState = queueState.toPrevious();
    if (newState == queueState) return; // No change

    _queueStateSubject.add(newState);
    _pinCurrentTracks(newState);
    _prefetchService.updatePrefetchQueue(
        newState.tracks, newState.currentIndex);

    if (_sourceIndexMap.containsKey(newState.currentIndex)) {
      await _audioPlayer.seek(Duration.zero,
          index: _sourceIndexMap[newState.currentIndex]);
    } else {
      await _addTrackToSource(newState.currentTrack!, newState.currentIndex);
      await _audioPlayer.seek(Duration.zero,
          index: _sourceIndexMap[newState.currentIndex]);
    }
  }

  /// Jump to specific track in queue.
  Future<void> skipToIndex(int index) async {
    final newState = queueState.toIndex(index);
    if (newState == queueState) return;

    _queueStateSubject.add(newState);
    _pinCurrentTracks(newState);
    _prefetchService.updatePrefetchQueue(
        newState.tracks, newState.currentIndex);

    if (_sourceIndexMap.containsKey(index)) {
      await _audioPlayer.seek(Duration.zero, index: _sourceIndexMap[index]);
    } else {
      await _addTrackToSource(newState.currentTrack!, index);
      await _audioPlayer.seek(Duration.zero, index: _sourceIndexMap[index]);
    }
  }

  /// Toggle shuffle mode.
  void toggleShuffle() {
    final newState = queueState.toggleShuffle();
    _queueStateSubject.add(newState);
    _prefetchService.updatePrefetchQueue(
        newState.displayTracks, newState.currentIndex);
  }

  /// Toggle repeat mode.
  void toggleRepeatMode() {
    final newState = queueState.withNextRepeatMode();
    _queueStateSubject.add(newState);
    _audioPlayer.setLoopMode(newState.repeatMode);
  }

  /// Add track to queue.
  void addToQueue(SongModel track, {bool playNext = false}) {
    final newState = queueState.withAddedTrack(track, addNext: playNext);
    _queueStateSubject.add(newState);
  }

  /// Remove track from queue.
  void removeFromQueue(int index) {
    final newState = queueState.withRemovedTrack(index);
    _queueStateSubject.add(newState);
  }

  /// Clear queue.
  Future<void> clearQueue() async {
    await stop();
    _queueStateSubject.add(QueueState.empty);
    _audioSource?.clear();
    _sourceIndexMap.clear();
  }

  // ========== Private Methods ==========

  void _setupPlayerListeners() {
    // Listen to current index changes (for gapless advance)
    _audioPlayer.currentIndexStream.listen((index) {
      if (index == null) return;

      // Find queue index from source index
      final queueIndex = _sourceIndexMap.entries
          .firstWhere((e) => e.value == index, orElse: () => MapEntry(-1, -1))
          .key;

      if (queueIndex >= 0 && queueIndex != queueState.currentIndex) {
        final newState = queueState.toIndex(queueIndex);
        _queueStateSubject.add(newState);
        _pinCurrentTracks(newState);
        _prefetchService.updatePrefetchQueue(
            newState.tracks, newState.currentIndex);
      }
    });

    // Listen to playback state
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (queueState.repeatMode == LoopMode.one) {
          _audioPlayer.seek(Duration.zero);
          _audioPlayer.play();
        } else if (!queueState.hasNext) {
          _updateStatus(PlaybackStatus.completed);
        }
      } else if (state.processingState == ProcessingState.buffering) {
        _updateStatus(PlaybackStatus.buffering);
      } else if (state.playing) {
        _updateStatus(PlaybackStatus.playing);
      } else if (!state.playing &&
          state.processingState == ProcessingState.ready) {
        _updateStatus(PlaybackStatus.paused);
      }
    });

    // Listen to errors
    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (error) => _handleError('Playback error', error),
    );
  }

  /// Build ConcatenatingAudioSource for gapless playback.
  Future<void> _buildAudioSource(QueueState state) async {
    debugPrint(
        'EnhancedAudioPlayer: Building audio source for ${state.tracks.length} tracks, starting at index ${state.currentIndex}');
    _audioSource?.clear();
    _sourceIndexMap.clear();

    final sources = <AudioSource>[];

    // Build sources for current and next few tracks
    final tracksToLoad = <int>[];
    for (int i = state.currentIndex;
        i < state.currentIndex + 3 && i < state.tracks.length;
        i++) {
      tracksToLoad.add(i);
    }

    debugPrint('EnhancedAudioPlayer: Will load ${tracksToLoad.length} tracks');

    for (final index in tracksToLoad) {
      final track = state.trackAt(index);
      if (track == null) continue;

      try {
        debugPrint(
            'EnhancedAudioPlayer: Resolving stream for track: ${track.title} (${track.id})');
        final resolved = await _streamResolver.resolveStream(track).timeout(
              const Duration(seconds: 20),
              onTimeout: () => throw Exception(
                  'Stream resolution timeout for ${track.title}'),
            );
        debugPrint(
            'EnhancedAudioPlayer: Got stream URL (local: ${resolved.isLocal})');
        final source =
            _createAudioSource(track, resolved.url, resolved.isLocal);
        sources.add(source);
        _sourceIndexMap[index] = sources.length - 1;
        debugPrint('EnhancedAudioPlayer: Successfully added track to sources');
      } catch (e, stack) {
        // Log the error but continue with other tracks
        debugPrint(
            'EnhancedAudioPlayer: Failed to resolve track ${track.id}: $e');
        debugPrint('EnhancedAudioPlayer: Stack trace: $stack');
        _handleError('Failed to load: ${track.title}', e);
        continue;
      }
    }

    if (sources.isEmpty) {
      debugPrint('EnhancedAudioPlayer: No tracks could be loaded!');
      throw Exception(
          'No tracks could be loaded. Please check your internet connection.');
    }

    debugPrint(
        'EnhancedAudioPlayer: Created audio source with ${sources.length} tracks');
    _audioSource = ConcatenatingAudioSource(children: sources);
    await _audioPlayer.setAudioSource(_audioSource!,
        preload: false); // We control preloading
  }

  /// Add a single track to audio source.
  Future<void> _addTrackToSource(SongModel track, int queueIndex) async {
    if (_audioSource == null) return;

    try {
      final resolved = await _streamResolver.resolveStream(track);
      final source = _createAudioSource(track, resolved.url, resolved.isLocal);

      await _audioSource!.add(source);
      _sourceIndexMap[queueIndex] = _audioSource!.length - 1;
    } catch (e) {
      _handleError('Failed to add track', e);
    }
  }

  AudioSource _createAudioSource(SongModel track, String url, bool isLocal) {
    // Custom headers to prevent YouTube 403 errors
    final headers = <String, String>{
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 12) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.58 Mobile Safari/537.36',
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Origin': 'https://www.youtube.com',
      'Referer': 'https://www.youtube.com/',
    };

    if (isLocal) {
      return AudioSource.file(
        url,
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artist: track.artist,
          duration: track.duration,
          artUri: Uri.parse(track.thumbnailUrl),
        ),
      );
    } else {
      return AudioSource.uri(
        Uri.parse(url),
        headers: headers,
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artist: track.artist,
          duration: track.duration,
          artUri: Uri.parse(track.thumbnailUrl),
        ),
      );
    }
  }

  void _pinCurrentTracks(QueueState state) {
    final trackIds = <String>[];
    if (state.currentTrack != null) {
      trackIds.add(state.currentTrack!.id);
    }
    if (state.nextTrack != null) {
      trackIds.add(state.nextTrack!.id);
    }
    _cacheManager.pinTracks(trackIds);
  }

  /// Start timer to refresh URLs before expiry.
  void _startUrlRefreshTimer() {
    _urlRefreshTimer?.cancel();

    // Check every 5 seconds if next track needs URL refresh
    _urlRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final nextTrack = queueState.nextTrack;
      if (nextTrack != null) {
        // Check remaining time of current track
        final remaining = duration != null
            ? duration! - position
            : const Duration(seconds: 30);

        // If less than 15 seconds remaining, pre-resolve next track
        if (remaining.inSeconds < 15) {
          _streamResolver.preResolveIfNeeded(nextTrack);
        }
      }
    });
  }

  void _updateStatus(PlaybackStatus status) {
    if (!_isDisposed) {
      _playbackStatusSubject.add(status);
    }
  }

  void _handleError(String message, dynamic error) {
    if (!_isDisposed) {
      _errorSubject.add(PlayerError(
        message: message,
        error: error,
        timestamp: DateTime.now(),
      ));
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _urlRefreshTimer?.cancel();
    _prefetchService.dispose();

    await _audioPlayer.dispose();
    await _queueStateSubject.close();
    await _playbackStatusSubject.close();
    await _errorSubject.close();
  }
}

/// Playback status enum.
enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  stopped,
  completed,
  error,
}

extension PlaybackStatusExtension on PlaybackStatus {
  bool get isActive =>
      this == PlaybackStatus.playing ||
      this == PlaybackStatus.paused ||
      this == PlaybackStatus.buffering;

  bool get canPlay =>
      this == PlaybackStatus.paused ||
      this == PlaybackStatus.stopped ||
      this == PlaybackStatus.completed;
}

/// Player error information.
class PlayerError {
  final String message;
  final dynamic error;
  final DateTime timestamp;

  PlayerError({
    required this.message,
    required this.error,
    required this.timestamp,
  });

  @override
  String toString() => 'PlayerError: $message - $error';
}
