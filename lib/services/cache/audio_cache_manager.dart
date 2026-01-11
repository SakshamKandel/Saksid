import 'dart:io';
import 'package:rxdart/rxdart.dart';
import '../../core/enums/cache_status.dart';
import '../../data/models/song_model.dart';
import 'memory_cache.dart';
import 'disk_cache.dart';

/// Stream URL with expiration tracking.
class CachedStreamUrl {
  final String url;
  final DateTime resolvedAt;
  final Duration validFor;

  CachedStreamUrl({
    required this.url,
    required this.resolvedAt,
    this.validFor = const Duration(hours: 5),
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  DateTime get expiresAt => resolvedAt.add(validFor);

  /// Check if URL should be refreshed (within 10 seconds of expiry).
  bool get shouldRefresh {
    final refreshThreshold = expiresAt.subtract(const Duration(seconds: 10));
    return DateTime.now().isAfter(refreshThreshold);
  }
}

/// Unified cache manager for audio content.
///
/// Coordinates between memory and disk caches with smart eviction.
/// Provides single interface for all caching operations.
class AudioCacheManager {
  // Memory caches (small, fast)
  final MemoryCache<String, CachedStreamUrl> _urlCache;
  final MemoryCache<String, Map<String, dynamic>> _manifestCache;
  final MemoryCache<String, SongModel> _metadataCache;

  // Disk cache (large, persistent)
  final DiskCache _diskCache;

  // Track pinned items (current + next track)
  final Set<String> _pinnedTrackIds = {};

  final BehaviorSubject<AudioCacheStats> _statsSubject =
      BehaviorSubject.seeded(AudioCacheStats.empty);

  Stream<AudioCacheStats> get statsStream => _statsSubject.stream;

  AudioCacheManager({
    int maxUrlCacheSize = 50,
    int maxManifestCacheSize = 30,
    int maxMetadataCacheSize = 200,
    int maxDiskCacheSizeBytes = 1024 * 1024 * 1024, // 1GB
  })  : _urlCache = MemoryCache(maxSize: maxUrlCacheSize),
        _manifestCache = MemoryCache(maxSize: maxManifestCacheSize),
        _metadataCache = MemoryCache(maxSize: maxMetadataCacheSize),
        _diskCache = DiskCache(maxSizeBytes: maxDiskCacheSizeBytes);

  /// Initialize caches.
  Future<void> init() async {
    await _diskCache.init();
    _updateStats();

    // Listen to disk cache changes
    _diskCache.statsStream.listen((_) => _updateStats());
  }

  // ========== URL Cache ==========

  /// Get cached stream URL if valid.
  CachedStreamUrl? getStreamUrl(String trackId) {
    final cached = _urlCache.get(trackId);
    if (cached == null || cached.isExpired) {
      _urlCache.remove(trackId);
      return null;
    }
    return cached;
  }

  /// Cache a resolved stream URL.
  void cacheStreamUrl(String trackId, String url) {
    _urlCache.put(
      trackId,
      CachedStreamUrl(url: url, resolvedAt: DateTime.now()),
      ttl: const Duration(hours: 5),
    );
    _updateStats();
  }

  /// Check if URL needs refreshing (near expiry).
  bool urlNeedsRefresh(String trackId) {
    final cached = _urlCache.get(trackId);
    return cached?.shouldRefresh ?? true;
  }

  // ========== Manifest Cache ==========

  /// Get cached manifest data.
  Map<String, dynamic>? getManifest(String trackId) {
    return _manifestCache.get(trackId);
  }

  /// Cache manifest data.
  void cacheManifest(String trackId, Map<String, dynamic> manifest) {
    _manifestCache.put(trackId, manifest, ttl: const Duration(hours: 4));
    _updateStats();
  }

  // ========== Metadata Cache ==========

  /// Get cached track metadata.
  SongModel? getMetadata(String trackId) {
    return _metadataCache.get(trackId);
  }

  /// Cache track metadata.
  void cacheMetadata(SongModel song) {
    _metadataCache.put(song.id, song);
    _updateStats();
  }

  /// Cache multiple tracks' metadata.
  void cacheMetadataBatch(List<SongModel> songs) {
    for (final song in songs) {
      _metadataCache.put(song.id, song);
    }
    _updateStats();
  }

  // ========== Disk Cache ==========

  /// Get file path for cached audio.
  Future<String?> getAudioFilePath(String trackId) async {
    return await _diskCache.getFilePath(trackId);
  }

  /// Check if audio is cached on disk.
  bool isAudioCached(String trackId) {
    return _diskCache.containsKey(trackId);
  }

  /// Get file handle for streaming write.
  Future<File> getAudioFileForWrite(String trackId) async {
    final fileName = _sanitizeFileName('$trackId.audio');
    return await _diskCache.getFileForWrite(trackId, fileName);
  }

  /// Register audio file after write.
  Future<void> registerAudioFile(
    String trackId,
    String fileName,
    int sizeBytes, {
    String? title,
    String? artist,
  }) async {
    await _diskCache.registerFile(trackId, fileName, sizeBytes, extra: {
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
    });
    _updateStats();
  }

  /// Remove cached audio file.
  Future<bool> removeAudio(String trackId) async {
    final result = await _diskCache.remove(trackId);
    _updateStats();
    return result;
  }

  // ========== Pinning ==========

  /// Pin tracks to prevent eviction (current + next).
  void pinTracks(List<String> trackIds) {
    // Unpin previous
    for (final id in _pinnedTrackIds) {
      _diskCache.unpin(id);
    }
    _pinnedTrackIds.clear();

    // Pin new
    for (final id in trackIds) {
      _pinnedTrackIds.add(id);
      _diskCache.pin(id);
    }
  }

  /// Unpin all tracks.
  void unpinAllTracks() {
    _diskCache.unpinAll();
    _pinnedTrackIds.clear();
  }

  // ========== Cache Status ==========

  /// Get cache status for a track.
  CacheStatus getCacheStatus(SongModel song) {
    // Check if downloaded (user-initiated)
    if (song.isDownloaded && song.localPath != null) {
      return CacheStatus.downloaded;
    }

    // Check disk cache
    if (_diskCache.containsKey(song.id)) {
      return CacheStatus.disk;
    }

    // Check memory cache (URL or manifest)
    final hasUrl = _urlCache.containsKey(song.id);
    final hasManifest = _manifestCache.containsKey(song.id);
    if (hasUrl || hasManifest) {
      return CacheStatus.memory;
    }

    return CacheStatus.remote;
  }

  /// Get cache status for multiple tracks.
  Map<String, CacheStatus> getCacheStatusBatch(List<SongModel> songs) {
    return {
      for (final song in songs) song.id: getCacheStatus(song),
    };
  }

  // ========== Cleanup ==========

  /// Clear memory caches.
  void clearMemoryCache() {
    _urlCache.clear();
    _manifestCache.clear();
    _metadataCache.clear();
    _updateStats();
  }

  /// Clear disk cache.
  Future<void> clearDiskCache() async {
    await _diskCache.clear();
    _updateStats();
  }

  /// Clear all caches.
  Future<void> clearAll() async {
    clearMemoryCache();
    await clearDiskCache();
  }

  /// Purge expired entries from memory caches.
  void purgeExpired() {
    _urlCache.purgeExpired();
    _manifestCache.purgeExpired();
    _metadataCache.purgeExpired();
    _updateStats();
  }

  // ========== Stats ==========

  void _updateStats() {
    _statsSubject.add(AudioCacheStats(
      urlCacheSize: _urlCache.length,
      manifestCacheSize: _manifestCache.length,
      metadataCacheSize: _metadataCache.length,
      diskCacheStats: _diskCache.currentStats,
      pinnedCount: _pinnedTrackIds.length,
    ));
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<void> dispose() async {
    await _statsSubject.close();
    await _diskCache.dispose();
  }
}

class AudioCacheStats {
  final int urlCacheSize;
  final int manifestCacheSize;
  final int metadataCacheSize;
  final DiskCacheStats diskCacheStats;
  final int pinnedCount;

  AudioCacheStats({
    required this.urlCacheSize,
    required this.manifestCacheSize,
    required this.metadataCacheSize,
    required this.diskCacheStats,
    required this.pinnedCount,
  });

  static final empty = AudioCacheStats(
    urlCacheSize: 0,
    manifestCacheSize: 0,
    metadataCacheSize: 0,
    diskCacheStats: DiskCacheStats.empty,
    pinnedCount: 0,
  );

  int get totalMemoryEntries =>
      urlCacheSize + manifestCacheSize + metadataCacheSize;

  @override
  String toString() {
    return 'AudioCacheStats(memory: $totalMemoryEntries entries, '
        'disk: ${diskCacheStats.formattedSize}, pinned: $pinnedCount)';
  }
}
