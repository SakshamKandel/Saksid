import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'song_model.dart';

part 'playlist_model.g.dart';

@HiveType(typeId: 1)
class PlaylistModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? thumbnailUrl;

  @HiveField(3)
  final List<SongModel> songs;

  @HiveField(4)
  final DateTime createdAt;

  const PlaylistModel({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.songs = const [],
    required this.createdAt,
  });

  PlaylistModel copyWith({
    String? id,
    String? name,
    String? thumbnailUrl,
    List<SongModel>? songs,
    DateTime? createdAt,
  }) {
    return PlaylistModel(
      id: id ?? this.id,
      name: name ?? this.name,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      songs: songs ?? this.songs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, songs, createdAt];
}
