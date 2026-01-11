import 'dart:async';
import 'dart:io';
import 'package:rxdart/rxdart.dart';
import '../../data/models/song_model.dart';
import '../cache/audio_cache_manager.dart';
import '../../core/enums/cache_status.dart';

/// Offline-first manager for network-aware behavior.
///
/// Features:
/// - Instant display of cached content (no blank screens)
/// - Graceful degradation on poor/no network
/// - Smart queue restoration on reconnect
/// - Offline library access
class OfflineManager {
  final AudioCacheManager _cacheManager;

  final BehaviorSubject<NetworkStatus> _networkStatusSubject =
      BehaviorSubject.seeded(NetworkStatus.unknown);

  final BehaviorSubject<OfflineState> _offlineStateSubject =
      BehaviorSubject.seeded(OfflineState.online);

  Timer? _connectivityCheckTimer;

  Stream<NetworkStatus> get networkStatusStream => _networkStatusSubject.stream;
  NetworkStatus get networkStatus => _networkStatusSubject.value;

  Stream<OfflineState> get offlineStateStream => _offlineStateSubject.stream;
  OfflineState get offlineState => _offlineStateSubject.value;

  bool get isOnline => offlineState == OfflineState.online;
  bool get isOffline => offlineState == OfflineState.offline;

  OfflineManager({
    required AudioCacheManager cacheManager,
  }) : _cacheManager = cacheManager;

  /// Initialize and start monitoring connectivity.
  Future<void> init() async {
    // Check initial connectivity
    await _checkConnectivity();

    // Periodically check connectivity (every 30 seconds)
    _connectivityCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      // Simple connectivity check by attempting to lookup a known host
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _handleConnectivityChange(NetworkStatus.wifi, OfflineState.online);
      } else {
        _handleConnectivityChange(NetworkStatus.none, OfflineState.offline);
      }
    } on SocketException catch (_) {
      _handleConnectivityChange(NetworkStatus.none, OfflineState.offline);
    } on TimeoutException catch (_) {
      _handleConnectivityChange(NetworkStatus.none, OfflineState.offline);
    } catch (_) {
      // Keep current state on unknown errors
    }
  }

  void _handleConnectivityChange(NetworkStatus status, OfflineState state) {
    final previousState = _offlineStateSubject.value;
    _networkStatusSubject.add(status);
    _offlineStateSubject.add(state);

    // Trigger restoration if coming back online
    if (previousState == OfflineState.offline && state == OfflineState.online) {
      _onNetworkRestored();
    }
  }

  void _onNetworkRestored() {
    // Could trigger: refresh expired URLs, sync queue, etc.
    // Handled by other services listening to offlineStateStream
  }

  /// Force a connectivity check.
  Future<void> refreshConnectivity() async {
    await _checkConnectivity();
  }

  // ========== Offline-First Data Access ==========

  /// Get playable tracks from a list, prioritizing cached ones.
  /// Returns immediately with cached tracks, then streams network tracks.
  Stream<List<SongModel>> getPlayableTracks(List<SongModel> tracks) async* {
    // Phase 1: Immediately return cached/downloaded tracks
    final cachedTracks = tracks.where((t) {
      final status = _cacheManager.getCacheStatus(t);
      return status.isLocal;
    }).toList();

    if (cachedTracks.isNotEmpty) {
      yield cachedTracks;
    }

    // Phase 2: If online, yield all tracks
    if (isOnline) {
      yield tracks;
    }
  }

  /// Check if a track is playable (offline or online).
  bool isTrackPlayable(SongModel track) {
    final status = _cacheManager.getCacheStatus(track);

    // Local tracks always playable
    if (status.isLocal) return true;

    // Remote tracks need network
    return isOnline;
  }

  /// Get offline-available tracks from a list.
  List<SongModel> getOfflineAvailableTracks(List<SongModel> tracks) {
    return tracks.where((t) {
      final status = _cacheManager.getCacheStatus(t);
      return status.isLocal;
    }).toList();
  }

  /// Get cache status summary for tracks.
  CacheStatusSummary getCacheStatusSummary(List<SongModel> tracks) {
    int downloaded = 0;
    int diskCached = 0;
    int memoryCached = 0;
    int remote = 0;

    for (final track in tracks) {
      switch (_cacheManager.getCacheStatus(track)) {
        case CacheStatus.downloaded:
          downloaded++;
          break;
        case CacheStatus.disk:
          diskCached++;
          break;
        case CacheStatus.memory:
          memoryCached++;
          break;
        case CacheStatus.remote:
          remote++;
          break;
      }
    }

    return CacheStatusSummary(
      total: tracks.length,
      downloaded: downloaded,
      diskCached: diskCached,
      memoryCached: memoryCached,
      remote: remote,
    );
  }

  // ========== Queue Restoration ==========

  /// Filter queue to only playable tracks based on network status.
  List<SongModel> filterPlayableQueue(List<SongModel> queue) {
    if (isOnline) return queue;

    // Offline: only return locally cached tracks
    return getOfflineAvailableTracks(queue);
  }

  /// Check if queue can be played (at least one track playable).
  bool canPlayQueue(List<SongModel> queue) {
    return queue.any((t) => isTrackPlayable(t));
  }

  /// Get next playable track index from current position.
  int? getNextPlayableIndex(List<SongModel> queue, int currentIndex) {
    for (int i = currentIndex + 1; i < queue.length; i++) {
      if (isTrackPlayable(queue[i])) {
        return i;
      }
    }

    // Wrap around if repeat all
    for (int i = 0; i < currentIndex; i++) {
      if (isTrackPlayable(queue[i])) {
        return i;
      }
    }

    return null;
  }

  // ========== Graceful Degradation ==========

  /// Execute action with offline fallback.
  Future<T> withOfflineFallback<T>({
    required Future<T> Function() online,
    required T Function() offline,
  }) async {
    if (isOffline) {
      return offline();
    }

    try {
      return await online();
    } catch (e) {
      // Network error - fall back to offline mode
      return offline();
    }
  }

  /// Execute action with timeout and offline fallback.
  Future<T?> withTimeoutFallback<T>({
    required Future<T> Function() action,
    Duration timeout = const Duration(seconds: 10),
    T? fallback,
  }) async {
    if (isOffline) {
      return fallback;
    }

    try {
      return await action().timeout(timeout);
    } catch (e) {
      return fallback;
    }
  }

  Future<void> dispose() async {
    _connectivityCheckTimer?.cancel();
    await _networkStatusSubject.close();
    await _offlineStateSubject.close();
  }
}

/// Network connection status.
enum NetworkStatus {
  unknown,
  none,
  wifi,
  mobile,
  ethernet,
  other,
}

extension NetworkStatusExtension on NetworkStatus {
  bool get hasConnection => this != NetworkStatus.none;

  bool get isUnmetered =>
      this == NetworkStatus.wifi || this == NetworkStatus.ethernet;

  String get displayName {
    switch (this) {
      case NetworkStatus.unknown:
        return 'Unknown';
      case NetworkStatus.none:
        return 'Offline';
      case NetworkStatus.wifi:
        return 'Wi-Fi';
      case NetworkStatus.mobile:
        return 'Mobile Data';
      case NetworkStatus.ethernet:
        return 'Ethernet';
      case NetworkStatus.other:
        return 'Connected';
    }
  }
}

/// Offline state.
enum OfflineState {
  online,
  offline,
}

/// Summary of cache status for a list of tracks.
class CacheStatusSummary {
  final int total;
  final int downloaded;
  final int diskCached;
  final int memoryCached;
  final int remote;

  CacheStatusSummary({
    required this.total,
    required this.downloaded,
    required this.diskCached,
    required this.memoryCached,
    required this.remote,
  });

  int get offlineAvailable => downloaded + diskCached;
  double get offlinePercent => total > 0 ? (offlineAvailable / total) * 100 : 0;

  @override
  String toString() {
    return 'CacheStatusSummary(total: $total, offline: $offlineAvailable, '
        'downloaded: $downloaded, cached: $diskCached, memory: $memoryCached, '
        'remote: $remote)';
  }
}
