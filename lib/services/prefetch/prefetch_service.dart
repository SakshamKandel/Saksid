import 'dart:async';
import 'package:rxdart/rxdart.dart';
import '../../data/models/song_model.dart';
import '../../data/datasources/remote/youtube_service.dart';
import '../../core/utils/rate_limiter.dart';
import '../cache/audio_cache_manager.dart';

/// Prefetch service with semaphore-controlled concurrency.
///
/// Features:
/// - Max 2 concurrent prefetch operations
/// - Automatic cancellation on queue change or skip
/// - Memory-safe: prefetches manifest/URL, not raw bytes
/// - Respects rate limiter
class PrefetchService {
  final YouTubeService _youtubeService;
  final RateLimiter _rateLimiter;
  final AudioCacheManager _cacheManager;

  // Semaphore: max 2 concurrent prefetches
  static const int _maxConcurrentPrefetches = 2;
  int _activePrefetches = 0;
  final List<_PrefetchTask> _pendingTasks = [];
  final Map<String, _PrefetchTask> _activeTasks = {};

  // Track IDs that should be prefetched
  final Set<String> _prefetchQueue = {};

  // Stream for prefetch status updates
  final BehaviorSubject<PrefetchStatus> _statusSubject =
      BehaviorSubject.seeded(PrefetchStatus.idle);

  Stream<PrefetchStatus> get statusStream => _statusSubject.stream;
  PrefetchStatus get currentStatus => _statusSubject.value;

  bool _isDisposed = false;
  bool _isPaused = false;

  PrefetchService({
    required YouTubeService youtubeService,
    required RateLimiter rateLimiter,
    required AudioCacheManager cacheManager,
  })  : _youtubeService = youtubeService,
        _rateLimiter = rateLimiter,
        _cacheManager = cacheManager;

  /// Update the prefetch queue based on current playback position.
  /// Call this when queue or current index changes.
  void updatePrefetchQueue(List<SongModel> tracks, int currentIndex) {
    if (_isDisposed) return;

    // Cancel tasks for tracks no longer in prefetch window
    final newPrefetchIds = <String>{};

    // Prefetch next 2 tracks (window of 2)
    for (int i = 1; i <= 2; i++) {
      final nextIndex = currentIndex + i;
      if (nextIndex < tracks.length) {
        newPrefetchIds.add(tracks[nextIndex].id);
      }
    }

    // Cancel tasks for tracks that left the window
    final toCancel = _prefetchQueue.difference(newPrefetchIds);
    for (final id in toCancel) {
      _cancelTask(id);
    }

    _prefetchQueue
      ..clear()
      ..addAll(newPrefetchIds);

    // Schedule prefetch for new tracks
    for (final id in newPrefetchIds) {
      final track = tracks.firstWhere((t) => t.id == id);
      _schedulePrefetch(track);
    }

    _updateStatus();
  }

  /// Schedule prefetch for a single track.
  void _schedulePrefetch(SongModel track) {
    // Skip if already cached or being prefetched
    if (_cacheManager.getStreamUrl(track.id) != null &&
        !_cacheManager.urlNeedsRefresh(track.id)) {
      return;
    }

    if (_activeTasks.containsKey(track.id)) {
      return;
    }

    if (_pendingTasks.any((t) => t.trackId == track.id)) {
      return;
    }

    final task = _PrefetchTask(
      trackId: track.id,
      track: track,
      createdAt: DateTime.now(),
    );

    _pendingTasks.add(task);
    _processQueue();
  }

  /// Process pending tasks up to concurrency limit.
  void _processQueue() {
    if (_isDisposed || _isPaused) return;

    while (_activePrefetches < _maxConcurrentPrefetches &&
        _pendingTasks.isNotEmpty) {
      final task = _pendingTasks.removeAt(0);

      // Skip if cancelled
      if (!_prefetchQueue.contains(task.trackId)) continue;

      _activePrefetches++;
      _activeTasks[task.trackId] = task;
      _executePrefetch(task);
    }

    _updateStatus();
  }

  /// Execute a prefetch task.
  Future<void> _executePrefetch(_PrefetchTask task) async {
    if (_isDisposed) return;

    try {
      // Use rate limiter to fetch stream URL
      final streamUrl = await _rateLimiter.schedule(
        () => _youtubeService.getStreamUrl(task.trackId),
      );

      // Cache the URL if task wasn't cancelled
      if (_prefetchQueue.contains(task.trackId)) {
        _cacheManager.cacheStreamUrl(task.trackId, streamUrl);

        // Also cache metadata if we have it
        _cacheManager.cacheMetadata(task.track.copyWith(streamUrl: streamUrl));
      }
    } catch (e) {
      // Log error but don't crash - prefetch is optional
      // The track will be fetched on-demand when played
    } finally {
      _activePrefetches--;
      _activeTasks.remove(task.trackId);
      _processQueue();
    }
  }

  /// Cancel a specific prefetch task.
  void _cancelTask(String trackId) {
    _pendingTasks.removeWhere((t) => t.trackId == trackId);
    // Note: Active tasks complete but their results are discarded
    // if trackId is not in _prefetchQueue
  }

  /// Cancel all prefetch tasks.
  void cancelAll() {
    _pendingTasks.clear();
    _prefetchQueue.clear();
    _updateStatus();
  }

  /// Pause prefetching (e.g., when app is backgrounded).
  void pause() {
    _isPaused = true;
    _updateStatus();
  }

  /// Resume prefetching.
  void resume() {
    _isPaused = false;
    _processQueue();
    _updateStatus();
  }

  /// Prefetch a specific track immediately (priority prefetch).
  Future<String?> prefetchNow(SongModel track) async {
    if (_isDisposed) return null;

    // Check cache first
    final cached = _cacheManager.getStreamUrl(track.id);
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    try {
      final streamUrl = await _rateLimiter.schedule(
        () => _youtubeService.getStreamUrl(track.id),
      );

      _cacheManager.cacheStreamUrl(track.id, streamUrl);
      _cacheManager.cacheMetadata(track.copyWith(streamUrl: streamUrl));

      return streamUrl;
    } catch (e) {
      return null;
    }
  }

  void _updateStatus() {
    if (_isDisposed) return;

    _statusSubject.add(PrefetchStatus(
      activeTasks: _activePrefetches,
      pendingTasks: _pendingTasks.length,
      isPaused: _isPaused,
      prefetchQueueSize: _prefetchQueue.length,
    ));
  }

  void dispose() {
    _isDisposed = true;
    cancelAll();
    _statusSubject.close();
  }
}

class _PrefetchTask {
  final String trackId;
  final SongModel track;
  final DateTime createdAt;

  _PrefetchTask({
    required this.trackId,
    required this.track,
    required this.createdAt,
  });
}

class PrefetchStatus {
  final int activeTasks;
  final int pendingTasks;
  final bool isPaused;
  final int prefetchQueueSize;

  PrefetchStatus({
    required this.activeTasks,
    required this.pendingTasks,
    required this.isPaused,
    required this.prefetchQueueSize,
  });

  static final idle = PrefetchStatus(
    activeTasks: 0,
    pendingTasks: 0,
    isPaused: false,
    prefetchQueueSize: 0,
  );

  bool get isActive => activeTasks > 0;
  int get totalTasks => activeTasks + pendingTasks;

  @override
  String toString() {
    return 'PrefetchStatus(active: $activeTasks, pending: $pendingTasks, '
        'paused: $isPaused, queue: $prefetchQueueSize)';
  }
}
