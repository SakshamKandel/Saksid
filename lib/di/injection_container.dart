import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Data sources
import '../data/datasources/remote/youtube_service.dart';

// Repositories
import '../data/repositories/music_repository.dart';
import '../data/repositories/playlist_repository.dart';

// Core utilities
import '../core/utils/rate_limiter.dart';

// Services - Cache
import '../services/cache/audio_cache_manager.dart';

// Services - Audio
import '../services/audio/audio_player_service.dart';
import '../services/audio/enhanced_audio_player_service.dart';

// Services - Stream
import '../services/stream/stream_resolver.dart';

// Services - Prefetch
import '../services/prefetch/prefetch_service.dart';

// Services - Offline
import '../services/offline/offline_manager.dart';

// Services - Other
import '../services/download/download_service.dart';
import '../services/playlist/playlist_service.dart';
import '../services/storage/local_storage_service.dart';

// Controllers
import '../presentation/controllers/player_controller.dart';
import '../presentation/controllers/enhanced_player_controller.dart';

final sl = GetIt.instance;

/// Initialize all dependencies with enhanced architecture.
Future<void> init() async {
  // ===== External =====
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // ===== Core Utilities =====
  sl.registerLazySingleton<RateLimiter>(
    () => RateLimiter(
      maxRequestsPerMinute: 30,
      jitterRange: const Duration(milliseconds: 300),
    ),
  );

  // ===== Data Sources =====
  sl.registerLazySingleton<YouTubeService>(() => YouTubeService());

  // ===== Cache Services =====
  final audioCacheManager = AudioCacheManager(
    maxUrlCacheSize: 50,
    maxManifestCacheSize: 30,
    maxMetadataCacheSize: 200,
    maxDiskCacheSizeBytes: 1024 * 1024 * 1024, // 1GB
  );
  // Skip disk cache init on web (dart:io not available)
  if (!kIsWeb) {
    try {
      await audioCacheManager.init();
    } catch (e) {
      debugPrint('Warning: AudioCacheManager init failed: $e');
    }
  }
  sl.registerLazySingleton<AudioCacheManager>(() => audioCacheManager);

  // ===== Playlist Service =====
  final playlistService = PlaylistService();
  await playlistService.init();
  sl.registerLazySingleton<PlaylistService>(() => playlistService);

  // ===== Storage Service =====
  sl.registerLazySingleton<LocalStorageService>(
    () => LocalStorageService(sl<SharedPreferences>()),
  );

  // ===== Repositories =====
  sl.registerLazySingleton<MusicRepository>(
    () => MusicRepositoryImpl(remoteDataSource: sl<YouTubeService>()),
  );

  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(sl<PlaylistService>()),
  );

  // ===== Stream Services =====
  sl.registerLazySingleton<StreamResolver>(
    () => StreamResolver(
      youtubeService: sl<YouTubeService>(),
      rateLimiter: sl<RateLimiter>(),
      cacheManager: sl<AudioCacheManager>(),
    ),
  );

  // ===== Prefetch Service =====
  sl.registerLazySingleton<PrefetchService>(
    () => PrefetchService(
      youtubeService: sl<YouTubeService>(),
      rateLimiter: sl<RateLimiter>(),
      cacheManager: sl<AudioCacheManager>(),
    ),
  );

  // ===== Offline Manager =====
  final offlineManager = OfflineManager(
    cacheManager: sl<AudioCacheManager>(),
  );
  // Skip init on web (uses dart:io)
  if (!kIsWeb) {
    try {
      await offlineManager.init();
    } catch (e) {
      debugPrint('Warning: OfflineManager init failed: $e');
    }
  }
  sl.registerLazySingleton<OfflineManager>(() => offlineManager);

  // ===== Audio Services =====
  // Legacy audio player service (for backwards compatibility)
  sl.registerLazySingleton<AudioPlayerService>(
    () => AudioPlayerService(sl<YouTubeService>()),
  );

  // Enhanced audio player service (new architecture)
  sl.registerLazySingleton<EnhancedAudioPlayerService>(
    () => EnhancedAudioPlayerService(
      streamResolver: sl<StreamResolver>(),
      prefetchService: sl<PrefetchService>(),
      cacheManager: sl<AudioCacheManager>(),
    ),
  );

  // ===== Download Service =====
  sl.registerLazySingleton<DownloadService>(
    () => DownloadService(sl<YouTubeService>()),
  );

  // ===== Controllers =====
  // Legacy controller (for backwards compatibility during migration)
  sl.registerFactory<PlayerController>(
    () => PlayerController(
      sl<AudioPlayerService>(),
      sl<DownloadService>(),
      sl<PlaylistService>(),
    ),
  );

  // Enhanced controller (new architecture)
  sl.registerFactory<EnhancedPlayerController>(
    () => EnhancedPlayerController(
      audioService: sl<EnhancedAudioPlayerService>(),
      downloadService: sl<DownloadService>(),
      playlistService: sl<PlaylistService>(),
      offlineManager: sl<OfflineManager>(),
      cacheManager: sl<AudioCacheManager>(),
    ),
  );
}

/// Reset all singletons (useful for testing).
Future<void> reset() async {
  await sl.reset();
}
