import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'presentation/controllers/enhanced_player_controller.dart';
import 'services/stats/stats_service.dart';
import 'presentation/screens/main_wrapper.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/library/library_screen.dart';
import 'presentation/screens/search/search_screen.dart';
import 'presentation/screens/player/player_screen.dart';
import 'presentation/screens/downloads/downloads_screen.dart';
import 'di/injection_container.dart';

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sl<EnhancedPlayerController>()),
        ChangeNotifierProvider(create: (_) => sl<StatsService>()),
      ],
      child: MaterialApp(
        title: 'Music Streaming',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: AppRoutes.splash,
        routes: {
          AppRoutes.splash: (context) => const SplashScreen(),
          AppRoutes.home: (context) => const MainWrapper(),
          AppRoutes.settings: (context) => const SettingsScreen(),
          AppRoutes.library: (context) => const LibraryScreen(),
          AppRoutes.search: (context) => const SearchScreen(),
          AppRoutes.player: (context) => const PlayerScreen(),
          AppRoutes.downloads: (context) => const DownloadsScreen(),
        },
      ),
    );
  }
}
