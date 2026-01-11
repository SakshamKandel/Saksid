import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/models/song_model.dart';
import '../../data/datasources/remote/youtube_service.dart';

class DownloadService {
  final YouTubeService _youtubeService;
  final Dio _dio = Dio();
  
  final BehaviorSubject<Map<String, DownloadProgress>> _downloadsSubject =
      BehaviorSubject.seeded({});
  final BehaviorSubject<List<SongModel>> _downloadedSongsSubject =
      BehaviorSubject.seeded([]);

  DownloadService(this._youtubeService);

  Stream<Map<String, DownloadProgress>> get downloadsStream =>
      _downloadsSubject.stream;
  Stream<List<SongModel>> get downloadedSongsStream =>
      _downloadedSongsSubject.stream;
  List<SongModel> get downloadedSongs => _downloadedSongsSubject.value;

  Future<Directory> get _downloadsDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDir.path}/music_downloads');
    
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    
    return downloadsDir;
  }

  Future<SongModel> downloadSong(SongModel song) async {
    try {
      _updateProgress(song.id, DownloadProgress(
        songId: song.id,
        progress: 0,
        status: DownloadStatus.downloading,
      ));

      final streamInfo = await _youtubeService.getAudioStreamInfo(song.id);
      final streamUrl = streamInfo.url.toString();
      
      final downloadsDir = await _downloadsDirectory;
      final sanitizedTitle = song.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
      final filePath = '${downloadsDir.path}/$sanitizedTitle.${streamInfo.container.name}';
      
      await _dio.download(
        streamUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _updateProgress(song.id, DownloadProgress(
              songId: song.id,
              progress: progress,
              status: DownloadStatus.downloading,
            ));
          }
        },
      );

      final thumbnailPath = await _downloadThumbnail(song);

      final downloadedSong = song.copyWith(
        localPath: filePath,
        isDownloaded: true,
        downloadedAt: DateTime.now(),
        thumbnailUrl: thumbnailPath ?? song.thumbnailUrl,
      );

      final currentDownloads = List<SongModel>.from(_downloadedSongsSubject.value);
      currentDownloads.add(downloadedSong);
      _downloadedSongsSubject.add(currentDownloads);

      _updateProgress(song.id, DownloadProgress(
        songId: song.id,
        progress: 1.0,
        status: DownloadStatus.completed,
      ));

      return downloadedSong;
    } catch (e) {
      _updateProgress(song.id, DownloadProgress(
        songId: song.id,
        progress: 0,
        status: DownloadStatus.failed,
        error: e.toString(),
      ));
      throw Exception('Failed to download song: $e');
    }
  }

  Future<String?> _downloadThumbnail(SongModel song) async {
    try {
      final downloadsDir = await _downloadsDirectory;
      final thumbnailPath = '${downloadsDir.path}/thumbnails/${song.id}.jpg';
      
      final thumbnailDir = Directory('${downloadsDir.path}/thumbnails');
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      await _dio.download(
        song.highResThumbnail ?? song.thumbnailUrl,
        thumbnailPath,
      );

      return thumbnailPath;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteDownload(String songId) async {
    try {
      final songs = List<SongModel>.from(_downloadedSongsSubject.value);
      final song = songs.firstWhere((s) => s.id == songId);
      
      if (song.localPath != null) {
        final file = File(song.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      songs.removeWhere((s) => s.id == songId);
      _downloadedSongsSubject.add(songs);
    } catch (e) {
      throw Exception('Failed to delete download: $e');
    }
  }

  void _updateProgress(String songId, DownloadProgress progress) {
    final downloads = Map<String, DownloadProgress>.from(_downloadsSubject.value);
    downloads[songId] = progress;
    _downloadsSubject.add(downloads);
  }

  void dispose() {
    _downloadsSubject.close();
    _downloadedSongsSubject.close();
  }
}

enum DownloadStatus {
  pending,
  downloading,
  completed,
  failed,
  cancelled,
}

class DownloadProgress {
  final String songId;
  final double progress;
  final DownloadStatus status;
  final String? error;

  DownloadProgress({
    required this.songId,
    required this.progress,
    required this.status,
    this.error,
  });
}
