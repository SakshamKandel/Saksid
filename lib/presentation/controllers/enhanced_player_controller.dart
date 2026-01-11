import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/song_model.dart';
import '../../data/models/playlist_model.dart';
import '../../domain/entities/queue_state.dart';
import '../../services/audio/enhanced_audio_player_service.dart';
import '../../services/download/download_service.dart';
import '../../services/playlist/playlist_service.dart';
import '../../services/offline/offline_manager.dart';
import '../../services/cache/audio_cache_manager.dart';
import '../../core/enums/cache_status.dart';

/// Enhanced player controller using the new bottleneck-resilient architecture.
///
/// Features:
/// - Immutable QueueState as single source of truth
/// - Gapless playback support
/// - Offline-first behavior
/// - Smart caching integration
/// - Prefetch awareness
class EnhancedPlayerController extends ChangeNotifier {
  final EnhancedAudioPlayerService _audioService;
  final DownloadService _downloadService;
  final PlaylistService _playlistService;
  final OfflineManager _offlineManager;
  final AudioCacheManager _cacheManager;

  // State
  QueueState _queueState = QueueState.empty;
  PlaybackStatus _playbackStatus = PlaybackStatus.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isMiniPlayerVisible = false;
  PlayerError? _lastError;

  // Subscriptions
  final List<StreamSubscription> _subscriptions = [];

  EnhancedPlayerController({
    required EnhancedAudioPlayerService audioService,
    required DownloadService downloadService,
    required PlaylistService playlistService,
    required OfflineManager offlineManager,
    required AudioCacheManager cacheManager,
  })  : _audioService = audioService,
        _downloadService = downloadService,
        _playlistService = playlistService,
        _offlineManager = offlineManager,
        _cacheManager = cacheManager {
    _initListeners();
  }

  // ========== Getters ==========

  QueueState get queueState => _queueState;
  SongModel? get currentSong => _queueState.currentTrack;
  List<SongModel> get playlist => _queueState.tracks;
  List<SongModel> get displayPlaylist => _queueState.displayTracks;

  PlaybackStatus get playbackStatus => _playbackStatus;
  bool get isPlaying => _playbackStatus == PlaybackStatus.playing;
  bool get isLoading => _playbackStatus == PlaybackStatus.loading ||
                        _playbackStatus == PlaybackStatus.buffering;
  bool get isPaused => _playbackStatus == PlaybackStatus.paused;

  Duration get position => _position;
  Duration get duration => _duration;

  bool get isShuffle => _queueState.isShuffled;
  LoopMode get loopMode => _queueState.repeatMode;

  bool get isMiniPlayerVisible => _isMiniPlayerVisible;
  bool get hasNext => _queueState.hasNext;
  bool get hasPrevious => _queueState.hasPrevious;

  bool get isOnline => _offlineManager.isOnline;
  bool get isOffline => _offlineManager.isOffline;

  PlayerError? get lastError => _lastError;

  // Service accessors
  DownloadService get downloadService => _downloadService;
  PlaylistService get playlistService => _playlistService;
  OfflineManager get offlineManager => _offlineManager;

  // ========== Initialization ==========

  void _initListeners() {
    // Queue state stream
    _subscriptions.add(
      _audioService.queueStateStream.listen((state) {
        _queueState = state;
        _isMiniPlayerVisible = state.currentTrack != null;

        // Add to recently played
        if (state.currentTrack != null) {
          _playlistService.addToRecentlyPlayed(state.currentTrack!);
        }

        notifyListeners();
      }),
    );

    // Playback status stream
    _subscriptions.add(
      _audioService.playbackStatusStream.listen((status) {
        _playbackStatus = status;
        notifyListeners();
      }),
    );

    // Position stream
    _subscriptions.add(
      _audioService.positionStream.listen((pos) {
        _position = pos;
        notifyListeners();
      }),
    );

    // Duration stream
    _subscriptions.add(
      _audioService.durationStream.listen((dur) {
        _duration = dur ?? Duration.zero;
        notifyListeners();
      }),
    );

    // Error stream
    _subscriptions.add(
      _audioService.errorStream.listen((error) {
        _lastError = error;
        if (error != null) {
          debugPrint('Player error: ${error.message}');
        }
        notifyListeners();
      }),
    );

    // Offline state changes
    _subscriptions.add(
      _offlineManager.offlineStateStream.listen((_) {
        notifyListeners();
      }),
    );
  }

  // ========== Playback Control ==========

  /// Play a single song.
  Future<void> playSong(SongModel song) async {
    await playPlaylist([song], startIndex: 0);
  }

  /// Play a playlist of songs.
  Future<void> playPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    // Filter to playable tracks if offline
    final playableSongs = _offlineManager.filterPlayableQueue(songs);
    if (playableSongs.isEmpty) {
      _lastError = PlayerError(
        message: 'No playable tracks available offline',
        error: 'OfflineError',
        timestamp: DateTime.now(),
      );
      notifyListeners();
      return;
    }

    // Adjust start index if needed
    int adjustedIndex = startIndex;
    if (isOffline && playableSongs.length != songs.length) {
      // Find corresponding track in filtered list
      final targetSong = songs[startIndex];
      adjustedIndex = playableSongs.indexWhere((s) => s.id == targetSong.id);
      if (adjustedIndex == -1) adjustedIndex = 0;
    }

    await _audioService.playQueue(playableSongs, startIndex: adjustedIndex);
  }

  /// Toggle play/pause.
  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
  }

  /// Play.
  Future<void> play() async {
    await _audioService.play();
  }

  /// Pause.
  Future<void> pause() async {
    await _audioService.pause();
  }

  /// Stop playback.
  Future<void> stop() async {
    await _audioService.stop();
  }

  /// Skip to next track.
  Future<void> next() async {
    await _audioService.next();
  }

  /// Skip to previous track.
  Future<void> previous() async {
    await _audioService.previous();
  }

  /// Seek to position.
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  /// Skip to specific index in queue.
  Future<void> skipToIndex(int index) async {
    await _audioService.skipToIndex(index);
  }

  /// Toggle shuffle mode.
  void toggleShuffle() {
    _audioService.toggleShuffle();
  }

  /// Toggle repeat mode.
  void toggleLoopMode() {
    _audioService.toggleRepeatMode();
  }

  /// Add track to queue.
  void addToQueue(SongModel track, {bool playNext = false}) {
    _audioService.addToQueue(track, playNext: playNext);
    notifyListeners();
  }

  /// Remove track from queue.
  void removeFromQueue(int index) {
    _audioService.removeFromQueue(index);
    notifyListeners();
  }

  /// Clear queue.
  Future<void> clearQueue() async {
    await _audioService.clearQueue();
    notifyListeners();
  }

  // ========== Download ==========

  /// Download a song.
  Future<void> downloadSong(SongModel song) async {
    await _downloadService.downloadSong(song);
    notifyListeners();
  }

  /// Check if song is downloaded.
  bool isDownloaded(SongModel song) {
    return song.isDownloaded;
  }

  // ========== Cache Status ==========

  /// Get cache status for a track.
  CacheStatus getCacheStatus(SongModel track) {
    return _cacheManager.getCacheStatus(track);
  }

  /// Check if track is available offline.
  bool isOfflineAvailable(SongModel track) {
    final status = _cacheManager.getCacheStatus(track);
    return status.isLocal;
  }

  // ========== Favorites ==========

  /// Check if song is favorite.
  bool isFavorite(String songId) {
    return _playlistService.isFavorite(songId);
  }

  /// Toggle favorite status.
  Future<bool> toggleFavorite(SongModel song) async {
    final result = await _playlistService.toggleFavorite(song);
    notifyListeners();
    return result;
  }

  /// Get all favorites.
  List<SongModel> getFavorites() {
    return _playlistService.getFavorites();
  }

  // ========== Playlists ==========

  /// Get all playlists.
  List<PlaylistModel> getAllPlaylists() {
    return _playlistService.getAllPlaylists();
  }

  /// Create a new playlist.
  Future<PlaylistModel> createPlaylist(String name, {String? thumbnailUrl}) async {
    final playlist = await _playlistService.createPlaylist(name, thumbnailUrl: thumbnailUrl);
    notifyListeners();
    return playlist;
  }

  /// Delete a playlist.
  Future<void> deletePlaylist(String playlistId) async {
    await _playlistService.deletePlaylist(playlistId);
    notifyListeners();
  }

  /// Add song to playlist.
  Future<PlaylistModel?> addSongToPlaylist(String playlistId, SongModel song) async {
    final playlist = await _playlistService.addSongToPlaylist(playlistId, song);
    notifyListeners();
    return playlist;
  }

  /// Remove song from playlist.
  Future<PlaylistModel?> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = await _playlistService.removeSongFromPlaylist(playlistId, songId);
    notifyListeners();
    return playlist;
  }

  /// Get playlist by ID.
  PlaylistModel? getPlaylist(String id) {
    return _playlistService.getPlaylist(id);
  }

  // ========== Recently Played ==========

  /// Get recently played tracks.
  List<SongModel> getRecentlyPlayed({int limit = 20}) {
    return _playlistService.getRecentlyPlayed(limit: limit);
  }

  /// Clear recently played.
  Future<void> clearRecentlyPlayed() async {
    await _playlistService.clearRecentlyPlayed();
    notifyListeners();
  }

  // ========== Error Handling ==========

  /// Clear last error.
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // ========== Cleanup ==========

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
