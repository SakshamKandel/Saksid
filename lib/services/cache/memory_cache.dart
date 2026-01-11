import 'dart:collection';

/// Memory LRU cache for manifests, URLs, and metadata.
///
/// Fast access, small footprint. Stores lightweight data only:
/// - Stream manifests
/// - Resolved stream URLs with expiration
/// - Track metadata
class MemoryCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();

  MemoryCache({this.maxSize = 100});

  /// Get a cached value, returns null if not found or expired.
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check expiration
    if (entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
      _cache.remove(key);
      return null;
    }

    // Move to end (most recently used)
    _cache.remove(key);
    _cache[key] = entry.withUpdatedAccess();

    return entry.value;
  }

  /// Put a value in cache with optional TTL.
  void put(K key, V value, {Duration? ttl}) {
    // Remove if exists (to update position)
    _cache.remove(key);

    // Evict oldest if at capacity
    while (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheEntry(
      value: value,
      createdAt: DateTime.now(),
      lastAccessedAt: DateTime.now(),
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
      hitCount: 0,
    );
  }

  /// Check if key exists and is not expired.
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove a specific key.
  V? remove(K key) {
    return _cache.remove(key)?.value;
  }

  /// Clear all entries.
  void clear() {
    _cache.clear();
  }

  /// Get current cache size.
  int get length => _cache.length;

  /// Get all keys.
  Iterable<K> get keys => _cache.keys;

  /// Get cache statistics.
  CacheStats get stats {
    int expiredCount = 0;
    int totalHits = 0;

    for (final entry in _cache.values) {
      if (entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
        expiredCount++;
      }
      totalHits += entry.hitCount;
    }

    return CacheStats(
      size: _cache.length,
      maxSize: maxSize,
      expiredEntries: expiredCount,
      totalHits: totalHits,
    );
  }

  /// Remove expired entries.
  int purgeExpired() {
    final now = DateTime.now();
    final keysToRemove = <K>[];

    for (final entry in _cache.entries) {
      if (entry.value.expiresAt != null &&
          now.isAfter(entry.value.expiresAt!)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    return keysToRemove.length;
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime createdAt;
  final DateTime lastAccessedAt;
  final DateTime? expiresAt;
  final int hitCount;

  _CacheEntry({
    required this.value,
    required this.createdAt,
    required this.lastAccessedAt,
    this.expiresAt,
    required this.hitCount,
  });

  _CacheEntry<V> withUpdatedAccess() {
    return _CacheEntry(
      value: value,
      createdAt: createdAt,
      lastAccessedAt: DateTime.now(),
      expiresAt: expiresAt,
      hitCount: hitCount + 1,
    );
  }
}

class CacheStats {
  final int size;
  final int maxSize;
  final int expiredEntries;
  final int totalHits;

  CacheStats({
    required this.size,
    required this.maxSize,
    required this.expiredEntries,
    required this.totalHits,
  });

  double get utilizationPercent => (size / maxSize) * 100;

  @override
  String toString() {
    return 'CacheStats(size: $size/$maxSize, expired: $expiredEntries, hits: $totalHits)';
  }
}
