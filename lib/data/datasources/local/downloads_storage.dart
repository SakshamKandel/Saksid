import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadsStorage {
  Future<String> getDownloadsPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${directory.path}/music_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<File> getFile(String filename) async {
    final path = await getDownloadsPath();
    return File('$path/$filename');
  }

  Future<bool> deleteFile(String filename) async {
    final file = await getFile(filename);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }
}
