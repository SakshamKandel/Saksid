import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../models/song_model.dart';
import '../models/download_model.dart';

abstract class DownloadRepository {
  Future<Either<Failure, bool>> downloadSong(SongModel song);
  Future<Either<Failure, bool>> deleteDownload(String songId);
  Future<Either<Failure, List<SongModel>>> getDownloadedSongs();
  Future<Either<Failure, DownloadModel?>> getDownloadStatus(String songId);
  Stream<List<DownloadModel>> get downloadQueue;
}

class DownloadRepositoryImpl implements DownloadRepository {
  final dynamic downloadService; // Will be typed properly locally

  DownloadRepositoryImpl({required this.downloadService});

  @override
  Future<Either<Failure, bool>> downloadSong(SongModel song) async {
    try {
      await downloadService.downloadSong(song);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteDownload(String songId) async {
    try {
      await downloadService.deleteDownload(songId);
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SongModel>>> getDownloadedSongs() async {
    try {
      final songs = downloadService.downloadedSongs;
      return Right(songs);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DownloadModel?>> getDownloadStatus(String songId) async {
    // This is a simplified implementation wrapping the service
    return const Right(null); // Placeholder
  }

  @override
  Stream<List<DownloadModel>> get downloadQueue => const Stream.empty(); // Placeholder
}
