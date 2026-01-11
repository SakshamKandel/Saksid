import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app.dart';
import 'di/injection_container.dart' as di;
import 'data/models/song_model.dart';
import 'data/models/playlist_model.dart';
import 'data/models/artist_model.dart';
import 'data/models/album_model.dart';
import 'data/models/download_model.dart';
import 'core/adapters/duration_adapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize background audio
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.example.music_app.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
    );
  } catch (e) {
    debugPrint('JustAudioBackground init error: $e');
  }

  try {
    // Initialize Hive
    await Hive.initFlutter();

    // Register Hive Adapters
    // Duration adapter must be registered first (used by other models)
    if (!Hive.isAdapterRegistered(100)) {
      Hive.registerAdapter(DurationAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SongModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PlaylistModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ArtistModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AlbumModelAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(DownloadStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(DownloadModelAdapter());
    }
  } catch (e) {
    debugPrint('Hive init error: $e');
  }

  // Initialize dependency injection
  await di.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MusicApp());
}
