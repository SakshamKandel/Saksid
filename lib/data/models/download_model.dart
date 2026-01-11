import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'download_model.g.dart';

@HiveType(typeId: 4)
enum DownloadStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  downloading,
  @HiveField(2)
  completed,
  @HiveField(3)
  failed,
  @HiveField(4)
  cancelled,
  @HiveField(5)
  paused
}

@HiveType(typeId: 5)
class DownloadModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String songId;
  
  @HiveField(2)
  final double progress;
  
  @HiveField(3)
  final DownloadStatus status;
  
  @HiveField(4)
  final String? error;
  
  @HiveField(5)
  final String? path;
  
  @HiveField(6)
  final DateTime startedAt;

  const DownloadModel({
    required this.id,
    required this.songId,
    this.progress = 0.0,
    this.status = DownloadStatus.pending,
    this.error,
    this.path,
    required this.startedAt,
  });

  DownloadModel copyWith({
    String? id,
    String? songId,
    double? progress,
    DownloadStatus? status,
    String? error,
    String? path,
    DateTime? startedAt,
  }) {
    return DownloadModel(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      error: error ?? this.error,
      path: path ?? this.path,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  List<Object?> get props => [id, songId, progress, status, error, path];
}
