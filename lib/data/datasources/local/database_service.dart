import 'package:hive_flutter/hive_flutter.dart';
import '../../models/song_model.dart';
import '../../models/playlist_model.dart';

class DatabaseService {
  static const String songsBoxName = 'songs';
  static const String playlistsBoxName = 'playlists';
  static const String settingsBoxName = 'settings';
  static const String statsBoxName = 'stats';

  Future<void> init() async {
    // Register adapters
    // Hive.registerAdapter(SongModelAdapter()); // Already registered in main
    // Hive.registerAdapter(PlaylistModelAdapter());

    await Hive.openBox<SongModel>(songsBoxName);
    await Hive.openBox<PlaylistModel>(playlistsBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox(statsBoxName);
  }

  Box<SongModel> get songsBox => Hive.box<SongModel>(songsBoxName);
  Box<PlaylistModel> get playlistsBox =>
      Hive.box<PlaylistModel>(playlistsBoxName);
  Box get settingsBox => Hive.box(settingsBoxName);
  Box get statsBox => Hive.box(statsBoxName);

  // Methods to interact with DB
  Future<void> saveSong(SongModel song) async {
    await songsBox.put(song.id, song);
  }

  List<SongModel> getSavedSongs() {
    return songsBox.values.toList();
  }
}
