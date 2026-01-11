import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'song_model.dart';

part 'album_model.g.dart';

@HiveType(typeId: 3)
class AlbumModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String? thumbnailUrl;

  @HiveField(4)
  final List<SongModel> songs;

  const AlbumModel({
    required this.id,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    this.songs = const [],
  });

  @override
  List<Object?> get props => [id, title, artist, songs];
}
