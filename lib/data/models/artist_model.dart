import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'artist_model.g.dart';

@HiveType(typeId: 2)
class ArtistModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? thumbnailUrl;

  @HiveField(3)
  final String? description;

  const ArtistModel({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.description,
  });

  @override
  List<Object?> get props => [id, name, thumbnailUrl];
}
