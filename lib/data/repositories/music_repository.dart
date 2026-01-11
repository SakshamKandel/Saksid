import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../models/song_model.dart';
import '../datasources/remote/youtube_service.dart';

abstract class MusicRepository {
  Future<Either<Failure, List<SongModel>>> getTrendingMusic();
  Future<Either<Failure, List<SongModel>>> searchSongs(String query);
  Future<Either<Failure, SongModel>> getSongDetails(String id);
  Future<Either<Failure, String>> getStreamUrl(String id);
  Future<Either<Failure, List<SongModel>>> getArtistSongs(String artistName);
  Future<Either<Failure, List<SongModel>>> getRelatedSongs(String videoId);
}

class MusicRepositoryImpl implements MusicRepository {
  final YouTubeService remoteDataSource;

  MusicRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SongModel>>> getTrendingMusic() async {
    try {
      final songs = await remoteDataSource.getTrendingMusic();
      return Right(songs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SongModel>>> searchSongs(String query) async {
    try {
      final songs = await remoteDataSource.searchSongs(query);
      return Right(songs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SongModel>> getSongDetails(String id) async {
    try {
      final song = await remoteDataSource.getVideoDetails(id);
      return Right(song);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getStreamUrl(String id) async {
    try {
      final url = await remoteDataSource.getStreamUrl(id);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<SongModel>>> getArtistSongs(String artistName) async {
    try {
      final songs = await remoteDataSource.getArtistSongs(artistName);
      return Right(songs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, List<SongModel>>> getRelatedSongs(String videoId) async {
    try {
      final songs = await remoteDataSource.getRelatedSongs(videoId);
      return Right(songs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
