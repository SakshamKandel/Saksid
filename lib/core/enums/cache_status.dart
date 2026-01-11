/// Indicates where a track's audio data is currently available.
enum CacheStatus {
  /// Track audio not cached - must fetch from remote
  remote,

  /// Track audio is in memory cache (manifest/URL/partial stream)
  memory,

  /// Track audio is fully cached on disk
  disk,

  /// Track is downloaded (user-initiated persistent cache)
  downloaded,
}

/// Extension methods for CacheStatus
extension CacheStatusExtension on CacheStatus {
  /// Whether audio is available locally (no network needed)
  bool get isLocal =>
      this == CacheStatus.disk || this == CacheStatus.downloaded;

  /// Whether audio needs to be fetched from network
  bool get needsNetwork => this == CacheStatus.remote;

  /// Whether this is a user-initiated download (shouldn't be evicted)
  bool get isPersistent => this == CacheStatus.downloaded;

  /// Display name for debugging
  String get displayName {
    switch (this) {
      case CacheStatus.remote:
        return 'Remote';
      case CacheStatus.memory:
        return 'Memory';
      case CacheStatus.disk:
        return 'Disk';
      case CacheStatus.downloaded:
        return 'Downloaded';
    }
  }
}
