import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import '../../data/models/song_model.dart';
import '../../data/datasources/remote/youtube_service.dart';
import '../../core/utils/rate_limiter.dart';
import '../cache/audio_cache_manager.dart';

/// Two-phase stream resolution service.
///
/// Phase 1: Fast metadata fetch (search results) - no stream URL
/// Phase 2: Lazy stream URL resolution only when:
///   - Track is about to play (just-in-time)
///   - Track is within prefetch window
///
/// Handles URL expiration with just-in-time refresh (~10s before playback).
class StreamResolver {
  final YouTubeService _youtubeService;
  final RateLimiter _rateLimiter;
  final AudioCacheManager _cacheManager;

  // Track resolution in progress to avoid duplicate requests
  final Map<String, Completer<String>> _resolutionInProgress = {};

  StreamResolver({
    required YouTubeService youtubeService,
    required RateLimiter rateLimiter,
    required AudioCacheManager cacheManager,
  })  : _youtubeService = youtubeService,
        _rateLimiter = rateLimiter,
        _cacheManager = cacheManager;

  /// Resolve stream URL for a track.
  ///
  /// Returns cached URL if valid, otherwise fetches fresh URL.
  /// Handles concurrent requests for same track gracefully.
  Future<ResolvedStream> resolveStream(SongModel track) async {
    debugPrint(
        'StreamResolver: Resolving stream for track ${track.id} (${track.title})');

    // Phase 1: Check if downloaded (highest priority)
    if (track.isDownloaded && track.localPath != null) {
      debugPrint('StreamResolver: Found downloaded file for ${track.id}');
      return ResolvedStream(
        trackId: track.id,
        url: track.localPath!,
        isLocal: true,
        source: StreamSource.downloaded,
      );
    }

    // Phase 2: Check disk cache
    final diskPath = await _cacheManager.getAudioFilePath(track.id);
    if (diskPath != null) {
      debugPrint('StreamResolver: Found disk cache for ${track.id}');
      return ResolvedStream(
        trackId: track.id,
        url: diskPath,
        isLocal: true,
        source: StreamSource.diskCache,
      );
    }

    // Phase 3: Check memory cache for valid URL
    final cachedUrl = _cacheManager.getStreamUrl(track.id);
    if (cachedUrl != null && !cachedUrl.isExpired) {
      debugPrint('StreamResolver: Found memory cache URL for ${track.id}');
      return ResolvedStream(
        trackId: track.id,
        url: cachedUrl.url,
        isLocal: false,
        source: StreamSource.memoryCache,
        expiresAt: cachedUrl.expiresAt,
      );
    }

    // Phase 4: Check if already resolving (avoid duplicate requests)
    if (_resolutionInProgress.containsKey(track.id)) {
      debugPrint(
          'StreamResolver: Resolution already in progress for ${track.id}, waiting...');
      final url = await _resolutionInProgress[track.id]!.future;
      return ResolvedStream(
        trackId: track.id,
        url: url,
        isLocal: false,
        source: StreamSource.network,
      );
    }

    // Phase 5: Fetch fresh URL from YouTube
    debugPrint('StreamResolver: Fetching fresh URL for ${track.id}');
    return await _fetchFreshUrl(track);
  }

  /// Fetch fresh stream URL from YouTube.
  Future<ResolvedStream> _fetchFreshUrl(SongModel track) async {
    final completer = Completer<String>();
    _resolutionInProgress[track.id] = completer;

    try {
      debugPrint('StreamResolver: Getting fresh URL from YouTubeService...');
      final streamUrl = await _rateLimiter
          .schedule(
            () => _youtubeService.getStreamUrl(track.id),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Stream URL resolution timeout'),
          );
      debugPrint(
          'StreamResolver: Got fresh URL: ${streamUrl.substring(0, streamUrl.length > 50 ? 50 : streamUrl.length)}...');

      // Cache the URL
      _cacheManager.cacheStreamUrl(track.id, streamUrl);

      completer.complete(streamUrl);

      final cached = _cacheManager.getStreamUrl(track.id);

      return ResolvedStream(
        trackId: track.id,
        url: streamUrl,
        isLocal: false,
        source: StreamSource.network,
        expiresAt: cached?.expiresAt,
      );
    } catch (e, stack) {
      debugPrint('StreamResolver: Failed to fetch URL for ${track.id}: $e');
      debugPrint('StreamResolver: Stack trace: $stack');
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      _resolutionInProgress.remove(track.id);
    }
  }

  /// Check if stream URL needs refresh (near expiry).
  /// Call this ~10 seconds before next track starts.
  bool needsRefresh(String trackId) {
    return _cacheManager.urlNeedsRefresh(trackId);
  }

  /// Pre-resolve stream URL for upcoming track (just-in-time refresh).
  /// Call this 10 seconds before next track plays.
  Future<void> preResolveIfNeeded(SongModel track) async {
    if (!needsRefresh(track.id)) return;

    // Don't block - resolve in background
    unawaited(_fetchFreshUrl(track).catchError((_) {}));
  }

  /// Resolve multiple tracks (for queue building).
  /// Resolves in order, respecting rate limits.
  Stream<ResolvedStream> resolveMultiple(List<SongModel> tracks) async* {
    for (final track in tracks) {
      try {
        yield await resolveStream(track);
      } catch (e) {
        // Skip failed tracks
        continue;
      }
    }
  }

  /// Get cached stream info without network call.
  /// Returns null if not cached or expired.
  ResolvedStream? getCachedStream(SongModel track) {
    if (track.isDownloaded && track.localPath != null) {
      return ResolvedStream(
        trackId: track.id,
        url: track.localPath!,
        isLocal: true,
        source: StreamSource.downloaded,
      );
    }

    final cachedUrl = _cacheManager.getStreamUrl(track.id);
    if (cachedUrl != null && !cachedUrl.isExpired) {
      return ResolvedStream(
        trackId: track.id,
        url: cachedUrl.url,
        isLocal: false,
        source: StreamSource.memoryCache,
        expiresAt: cachedUrl.expiresAt,
      );
    }

    return null;
  }

  void dispose() {
    _resolutionInProgress.clear();
  }
}

/// Represents a resolved stream URL.
class ResolvedStream {
  final String trackId;
  final String url;
  final bool isLocal;
  final StreamSource source;
  final DateTime? expiresAt;

  ResolvedStream({
    required this.trackId,
    required this.url,
    required this.isLocal,
    required this.source,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get shouldRefresh {
    if (expiresAt == null) return false;
    final refreshThreshold = expiresAt!.subtract(const Duration(seconds: 10));
    return DateTime.now().isAfter(refreshThreshold);
  }

  @override
  String toString() {
    return 'ResolvedStream(track: $trackId, local: $isLocal, source: $source)';
  }
}

/// Source of the resolved stream.
enum StreamSource {
  /// User-downloaded file
  downloaded,

  /// Cached on disk (auto-cache)
  diskCache,

  /// Cached URL in memory
  memoryCache,

  /// Fresh fetch from network
  network,
}

extension StreamSourceExtension on StreamSource {
  bool get isLocal =>
      this == StreamSource.downloaded || this == StreamSource.diskCache;

  String get displayName {
    switch (this) {
      case StreamSource.downloaded:
        return 'Downloaded';
      case StreamSource.diskCache:
        return 'Cached';
      case StreamSource.memoryCache:
        return 'Memory';
      case StreamSource.network:
        return 'Streaming';
    }
  }
}
