import 'package:background_downloader/background_downloader.dart';
import '../../data/models/song_model.dart';
import '../notification/notification_service.dart';

class DownloadManager {
  final NotificationService _notificationService;

  DownloadManager(this._notificationService);

  Future<void> init() async {
    // TODO: Update configuration for background_downloader ^8.0.0
    // FileDownloader().configure(
    //   options: [
    //     FileDownloaderOption.notifications,
    //   ],
    // );
  }

  Future<void> enqueueDownload(SongModel song) async {
    // Implementation for background downloader
    final task = DownloadTask(
      url: song.streamUrl ?? '',
      filename: '${song.id}.mp3',
      displayName: song.title,
      directory: 'music',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
    );

    await FileDownloader().enqueue(task);
  }
}
