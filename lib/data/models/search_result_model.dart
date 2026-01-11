import 'package:equatable/equatable.dart';
import 'song_model.dart';
import 'artist_model.dart';
import 'album_model.dart';
import 'playlist_model.dart';

enum SearchResultType {
  song,
  artist,
  album,
  playlist,
}

class SearchResultModel extends Equatable {
  final SearchResultType type;
  final dynamic data;

  const SearchResultModel({
    required this.type,
    required this.data,
  });

  SongModel? get asSong => type == SearchResultType.song ? data as SongModel : null;
  ArtistModel? get asArtist => type == SearchResultType.artist ? data as ArtistModel : null;
  AlbumModel? get asAlbum => type == SearchResultType.album ? data as AlbumModel : null;
  PlaylistModel? get asPlaylist => type == SearchResultType.playlist ? data as PlaylistModel : null;

  @override
  List<Object?> get props => [type, data];
}
