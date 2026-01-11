import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String thumbnailUrl;

  @HiveField(4)
  final String? highResThumbnail;

  @HiveField(5)
  final Duration duration;

  @HiveField(6)
  final String? streamUrl;

  @HiveField(7)
  final String? localPath;

  @HiveField(8)
  final bool isDownloaded;

  @HiveField(9)
  final DateTime? downloadedAt;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    this.highResThumbnail,
    required this.duration,
    this.streamUrl,
    this.localPath,
    this.isDownloaded = false,
    this.downloadedAt,
  });

  SongModel copyWith({
    String? id,
    String? title,
    String? artist,
    String? thumbnailUrl,
    String? highResThumbnail,
    Duration? duration,
    String? streamUrl,
    String? localPath,
    bool? isDownloaded,
    DateTime? downloadedAt,
  }) {
    return SongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      highResThumbnail: highResThumbnail ?? this.highResThumbnail,
      duration: duration ?? this.duration,
      streamUrl: streamUrl ?? this.streamUrl,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, artist, isDownloaded];
}
