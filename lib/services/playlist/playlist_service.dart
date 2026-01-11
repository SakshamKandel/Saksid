import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/song_model.dart';

class PlaylistService {
  static const String _playlistBoxName = 'playlists';
  static const String _favoritesBoxName = 'favorites';
  static const String _recentlyPlayedBoxName = 'recently_played';

  Box<PlaylistModel>? _playlistBox;
  Box<SongModel>? _favoritesBox;
  Box<SongModel>? _recentlyPlayedBox;

  final _uuid = const Uuid();

  Future<void> init() async {
    try {
      _playlistBox = await Hive.openBox<PlaylistModel>(_playlistBoxName);
      _favoritesBox = await Hive.openBox<SongModel>(_favoritesBoxName);
      _recentlyPlayedBox = await Hive.openBox<SongModel>(_recentlyPlayedBoxName);
    } catch (e) {
      // If Hive fails, delete corrupted boxes and try again
      try {
        await Hive.deleteBoxFromDisk(_playlistBoxName);
        await Hive.deleteBoxFromDisk(_favoritesBoxName);
        await Hive.deleteBoxFromDisk(_recentlyPlayedBoxName);
        
        _playlistBox = await Hive.openBox<PlaylistModel>(_playlistBoxName);
        _favoritesBox = await Hive.openBox<SongModel>(_favoritesBoxName);
        _recentlyPlayedBox = await Hive.openBox<SongModel>(_recentlyPlayedBoxName);
      } catch (e2) {
        // Non-fatal: app will work without persistence
        debugPrint('PlaylistService: Hive init failed: $e2');
      }
    }
  }

  // Playlist Operations
  List<PlaylistModel> getAllPlaylists() {
    return _playlistBox?.values.toList() ?? [];
  }

  PlaylistModel? getPlaylist(String id) {
    return _playlistBox?.get(id);
  }

  Future<PlaylistModel> createPlaylist(String name, {String? thumbnailUrl}) async {
    final playlist = PlaylistModel(
      id: _uuid.v4(),
      name: name,
      thumbnailUrl: thumbnailUrl,
      songs: const [],
      createdAt: DateTime.now(),
    );

    await _playlistBox?.put(playlist.id, playlist);
    return playlist;
  }

  Future<void> updatePlaylist(PlaylistModel playlist) async {
    await _playlistBox?.put(playlist.id, playlist);
  }

  Future<void> deletePlaylist(String id) async {
    await _playlistBox?.delete(id);
  }

  Future<PlaylistModel?> addSongToPlaylist(String playlistId, SongModel song) async {
    final playlist = _playlistBox?.get(playlistId);
    if (playlist == null) return null;

    // Check if song already exists in playlist
    if (playlist.songs.any((s) => s.id == song.id)) {
      return playlist;
    }

    final updatedPlaylist = playlist.copyWith(
      songs: [...playlist.songs, song],
      thumbnailUrl: playlist.thumbnailUrl ?? song.thumbnailUrl,
    );

    await _playlistBox?.put(playlistId, updatedPlaylist);
    return updatedPlaylist;
  }

  Future<PlaylistModel?> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = _playlistBox?.get(playlistId);
    if (playlist == null) return null;

    final updatedSongs = playlist.songs.where((s) => s.id != songId).toList();
    final updatedPlaylist = playlist.copyWith(songs: updatedSongs);

    await _playlistBox?.put(playlistId, updatedPlaylist);
    return updatedPlaylist;
  }

  // Favorites Operations
  List<SongModel> getFavorites() {
    return _favoritesBox?.values.toList() ?? [];
  }

  bool isFavorite(String songId) {
    return _favoritesBox?.containsKey(songId) ?? false;
  }

  Future<void> addToFavorites(SongModel song) async {
    await _favoritesBox?.put(song.id, song);
  }

  Future<void> removeFromFavorites(String songId) async {
    await _favoritesBox?.delete(songId);
  }

  Future<bool> toggleFavorite(SongModel song) async {
    if (isFavorite(song.id)) {
      await removeFromFavorites(song.id);
      return false;
    } else {
      await addToFavorites(song);
      return true;
    }
  }

  // Recently Played Operations
  List<SongModel> getRecentlyPlayed({int limit = 20}) {
    final songs = _recentlyPlayedBox?.values.toList() ?? [];
    songs.sort((a, b) => (b.downloadedAt ?? DateTime(2000)).compareTo(a.downloadedAt ?? DateTime(2000)));
    return songs.take(limit).toList();
  }

  Future<void> addToRecentlyPlayed(SongModel song) async {
    // Use downloadedAt field to store play time for sorting
    final songWithTimestamp = song.copyWith(downloadedAt: DateTime.now());
    await _recentlyPlayedBox?.put(song.id, songWithTimestamp);

    // Keep only last 50 songs
    if ((_recentlyPlayedBox?.length ?? 0) > 50) {
      final songs = getRecentlyPlayed(limit: 100);
      if (songs.length > 50) {
        for (var i = 50; i < songs.length; i++) {
          await _recentlyPlayedBox?.delete(songs[i].id);
        }
      }
    }
  }

  Future<void> clearRecentlyPlayed() async {
    await _recentlyPlayedBox?.clear();
  }

  void dispose() {
    _playlistBox?.close();
    _favoritesBox?.close();
    _recentlyPlayedBox?.close();
  }
}
