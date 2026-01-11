import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../../services/playlist/playlist_service.dart';

abstract class PlaylistRepository {
  Future<Either<Failure, List<PlaylistModel>>> getPlaylists();
  Future<Either<Failure, PlaylistModel>> getPlaylist(String playlistId);
  Future<Either<Failure, PlaylistModel>> createPlaylist(String name, {String? thumbnailUrl});
  Future<Either<Failure, bool>> deletePlaylist(String playlistId);
  Future<Either<Failure, PlaylistModel>> addSongToPlaylist(String playlistId, SongModel song);
  Future<Either<Failure, PlaylistModel>> removeSongFromPlaylist(String playlistId, String songId);
  Future<Either<Failure, List<SongModel>>> getFavorites();
  Future<Either<Failure, bool>> toggleFavorite(SongModel song);
  bool isFavorite(String songId);
  Future<Either<Failure, List<SongModel>>> getRecentlyPlayed({int limit = 20});
  Future<Either<Failure, void>> addToRecentlyPlayed(SongModel song);
  Future<Either<Failure, void>> clearRecentlyPlayed();
}

class PlaylistRepositoryImpl implements PlaylistRepository {
  final PlaylistService _playlistService;

  PlaylistRepositoryImpl(this._playlistService);

  @override
  Future<Either<Failure, List<PlaylistModel>>> getPlaylists() async {
    try {
      final playlists = _playlistService.getAllPlaylists();
      return Right(playlists);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load playlists: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistModel>> getPlaylist(String playlistId) async {
    try {
      final playlist = _playlistService.getPlaylist(playlistId);
      if (playlist == null) {
        return Left(CacheFailure(message: 'Playlist not found'));
      }
      return Right(playlist);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistModel>> createPlaylist(String name, {String? thumbnailUrl}) async {
    try {
      final playlist = await _playlistService.createPlaylist(name, thumbnailUrl: thumbnailUrl);
      return Right(playlist);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to create playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deletePlaylist(String playlistId) async {
    try {
      await _playlistService.deletePlaylist(playlistId);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete playlist: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistModel>> addSongToPlaylist(String playlistId, SongModel song) async {
    try {
      final playlist = await _playlistService.addSongToPlaylist(playlistId, song);
      if (playlist == null) {
        return Left(CacheFailure(message: 'Playlist not found'));
      }
      return Right(playlist);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add song: $e'));
    }
  }

  @override
  Future<Either<Failure, PlaylistModel>> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final playlist = await _playlistService.removeSongFromPlaylist(playlistId, songId);
      if (playlist == null) {
        return Left(CacheFailure(message: 'Playlist not found'));
      }
      return Right(playlist);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to remove song: $e'));
    }
  }

  @override
  Future<Either<Failure, List<SongModel>>> getFavorites() async {
    try {
      final favorites = _playlistService.getFavorites();
      return Right(favorites);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load favorites: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleFavorite(SongModel song) async {
    try {
      final isFavorite = await _playlistService.toggleFavorite(song);
      return Right(isFavorite);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to toggle favorite: $e'));
    }
  }

  @override
  bool isFavorite(String songId) {
    return _playlistService.isFavorite(songId);
  }

  @override
  Future<Either<Failure, List<SongModel>>> getRecentlyPlayed({int limit = 20}) async {
    try {
      final songs = _playlistService.getRecentlyPlayed(limit: limit);
      return Right(songs);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load recently played: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> addToRecentlyPlayed(SongModel song) async {
    try {
      await _playlistService.addToRecentlyPlayed(song);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add to recently played: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearRecentlyPlayed() async {
    try {
      await _playlistService.clearRecentlyPlayed();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear recently played: $e'));
    }
  }
}
