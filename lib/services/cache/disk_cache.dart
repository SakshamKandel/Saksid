import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

/// Disk LRU cache for audio files.
///
/// Features:
/// - Configurable max size (default 1GB)
/// - Eviction by lastAccessed, with protection for frequently accessed files
/// - Pinning for currently playing + next track
/// - Metadata tracking for cache hits
class DiskCache {
  static const String _metadataFileName = 'cache_metadata.json';
  static const int defaultMaxSizeBytes = 1024 * 1024 * 1024; // 1GB

  final int maxSizeBytes;
  final String subdirectory;

  Directory? _cacheDir;
  final Map<String, DiskCacheEntry> _metadata = {};
  final Set<String> _pinnedKeys = {};

  final BehaviorSubject<DiskCacheStats> _statsSubject =
      BehaviorSubject.seeded(DiskCacheStats.empty);

  Stream<DiskCacheStats> get statsStream => _statsSubject.stream;
  DiskCacheStats get currentStats => _statsSubject.value;

  DiskCache({
    this.maxSizeBytes = defaultMaxSizeBytes,
    this.subdirectory = 'audio_cache',
  });

  /// Initialize the cache directory and load metadata.
  Future<void> init() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory('${appDir.path}/$subdirectory');

    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }

    await _loadMetadata();
    await _updateStats();
  }

  /// Get the file path for a cached item, or null if not cached.
  Future<String?> getFilePath(String key) async {
    final entry = _metadata[key];
    if (entry == null) return null;

    final file = File('${_cacheDir!.path}/${entry.fileName}');
    if (!await file.exists()) {
      _metadata.remove(key);
      await _saveMetadata();
      return null;
    }

    // Update access time
    _metadata[key] = entry.copyWith(
      lastAccessedAt: DateTime.now(),
      hitCount: entry.hitCount + 1,
    );
    await _saveMetadata();

    return file.path;
  }

  /// Check if a key is cached.
  bool containsKey(String key) {
    return _metadata.containsKey(key);
  }

  /// Get a file handle for writing. Caller is responsible for writing data.
  Future<File> getFileForWrite(String key, String fileName) async {
    await _ensureSpace(0); // Pre-check space
    return File('${_cacheDir!.path}/$fileName');
  }

  /// Register a cached file after writing.
  Future<void> registerFile(
    String key,
    String fileName,
    int sizeBytes, {
    Map<String, dynamic>? extra,
  }) async {
    await _ensureSpace(sizeBytes);

    _metadata[key] = DiskCacheEntry(
      key: key,
      fileName: fileName,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      hitCount: 0,
      extra: extra,
    );

    await _saveMetadata();
    await _updateStats();
  }

  /// Remove a cached item.
  Future<bool> remove(String key) async {
    final entry = _metadata.remove(key);
    if (entry == null) return false;

    final file = File('${_cacheDir!.path}/${entry.fileName}');
    if (await file.exists()) {
      await file.delete();
    }

    await _saveMetadata();
    await _updateStats();
    return true;
  }

  /// Pin a key to prevent eviction (e.g., currently playing).
  void pin(String key) {
    _pinnedKeys.add(key);
  }

  /// Unpin a key.
  void unpin(String key) {
    _pinnedKeys.remove(key);
  }

  /// Unpin all keys.
  void unpinAll() {
    _pinnedKeys.clear();
  }

  /// Clear all cached files.
  Future<void> clear() async {
    if (_cacheDir != null && await _cacheDir!.exists()) {
      await for (final entity in _cacheDir!.list()) {
        if (entity is File && !entity.path.endsWith(_metadataFileName)) {
          await entity.delete();
        }
      }
    }

    _metadata.clear();
    _pinnedKeys.clear();
    await _saveMetadata();
    await _updateStats();
  }

  /// Ensure there's space for a new file.
  Future<void> _ensureSpace(int requiredBytes) async {
    int currentSize = _calculateTotalSize();

    while (currentSize + requiredBytes > maxSizeBytes && _metadata.isNotEmpty) {
      final keyToEvict = _selectEvictionCandidate();
      if (keyToEvict == null) break;

      final entry = _metadata[keyToEvict]!;
      final file = File('${_cacheDir!.path}/${entry.fileName}');

      if (await file.exists()) {
        await file.delete();
        currentSize -= entry.sizeBytes;
      }

      _metadata.remove(keyToEvict);
    }

    await _saveMetadata();
  }

  /// Select the best candidate for eviction.
  /// Considers: not pinned, lastAccessed time, hit count.
  String? _selectEvictionCandidate() {
    String? candidate;
    DateTime? oldestAccess;
    int lowestHitCount = 999999;

    for (final entry in _metadata.entries) {
      // Skip pinned items
      if (_pinnedKeys.contains(entry.key)) continue;

      final accessTime = entry.value.lastAccessedAt;
      final hits = entry.value.hitCount;

      // Prefer items with fewer hits and older access time
      if (candidate == null ||
          hits < lowestHitCount ||
          (hits == lowestHitCount && accessTime.isBefore(oldestAccess!))) {
        candidate = entry.key;
        oldestAccess = accessTime;
        lowestHitCount = hits;
      }
    }

    return candidate;
  }

  int _calculateTotalSize() {
    return _metadata.values.fold(0, (sum, entry) => sum + entry.sizeBytes);
  }

  Future<void> _loadMetadata() async {
    final metadataFile = File('${_cacheDir!.path}/$_metadataFileName');

    if (await metadataFile.exists()) {
      try {
        final json = jsonDecode(await metadataFile.readAsString());
        final entries = (json['entries'] as List?) ?? [];

        for (final entryJson in entries) {
          final entry = DiskCacheEntry.fromJson(entryJson);
          _metadata[entry.key] = entry;
        }
      } catch (e) {
        // Corrupted metadata, start fresh
        _metadata.clear();
      }
    }

    // Verify files exist
    final keysToRemove = <String>[];
    for (final entry in _metadata.entries) {
      final file = File('${_cacheDir!.path}/${entry.value.fileName}');
      if (!await file.exists()) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _metadata.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      await _saveMetadata();
    }
  }

  Future<void> _saveMetadata() async {
    final metadataFile = File('${_cacheDir!.path}/$_metadataFileName');
    final json = {
      'entries': _metadata.values.map((e) => e.toJson()).toList(),
    };
    await metadataFile.writeAsString(jsonEncode(json));
  }

  Future<void> _updateStats() async {
    final totalSize = _calculateTotalSize();

    _statsSubject.add(DiskCacheStats(
      totalSizeBytes: totalSize,
      maxSizeBytes: maxSizeBytes,
      fileCount: _metadata.length,
      pinnedCount: _pinnedKeys.length,
    ));
  }

  Future<void> dispose() async {
    await _statsSubject.close();
  }
}

class DiskCacheEntry {
  final String key;
  final String fileName;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final int hitCount;
  final Map<String, dynamic>? extra;

  DiskCacheEntry({
    required this.key,
    required this.fileName,
    required this.sizeBytes,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.hitCount,
    this.extra,
  });

  DiskCacheEntry copyWith({
    DateTime? lastAccessedAt,
    int? hitCount,
  }) {
    return DiskCacheEntry(
      key: key,
      fileName: fileName,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      hitCount: hitCount ?? this.hitCount,
      extra: extra,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'fileName': fileName,
    'sizeBytes': sizeBytes,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'hitCount': hitCount,
    'extra': extra,
  };

  factory DiskCacheEntry.fromJson(Map<String, dynamic> json) {
    return DiskCacheEntry(
      key: json['key'],
      fileName: json['fileName'],
      sizeBytes: json['sizeBytes'],
      createdAt: DateTime.parse(json['createdAt']),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt']),
      hitCount: json['hitCount'] ?? 0,
      extra: json['extra'],
    );
  }
}

class DiskCacheStats {
  final int totalSizeBytes;
  final int maxSizeBytes;
  final int fileCount;
  final int pinnedCount;

  DiskCacheStats({
    required this.totalSizeBytes,
    required this.maxSizeBytes,
    required this.fileCount,
    required this.pinnedCount,
  });

  static final empty = DiskCacheStats(
    totalSizeBytes: 0,
    maxSizeBytes: 0,
    fileCount: 0,
    pinnedCount: 0,
  );

  double get utilizationPercent =>
      maxSizeBytes > 0 ? (totalSizeBytes / maxSizeBytes) * 100 : 0;

  String get formattedSize => _formatBytes(totalSizeBytes);
  String get formattedMaxSize => _formatBytes(maxSizeBytes);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  String toString() {
    return 'DiskCacheStats($formattedSize / $formattedMaxSize, '
        '$fileCount files, $pinnedCount pinned)';
  }
}
