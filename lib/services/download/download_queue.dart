import 'package:rxdart/rxdart.dart';
import '../../data/models/download_model.dart';

class DownloadQueue {
  final BehaviorSubject<List<DownloadModel>> _queueSubject = BehaviorSubject.seeded([]);

  Stream<List<DownloadModel>> get queueStream => _queueSubject.stream;
  List<DownloadModel> get currentQueue => _queueSubject.value;

  void add(DownloadModel item) {
    final list = List<DownloadModel>.from(currentQueue);
    list.add(item);
    _queueSubject.add(list);
  }

  void remove(String id) {
    final list = List<DownloadModel>.from(currentQueue);
    list.removeWhere((item) => item.id == id);
    _queueSubject.add(list);
  }

  void clear() {
    _queueSubject.add([]);
  }

  void dispose() {
    _queueSubject.close();
  }
}
