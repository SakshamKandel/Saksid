import '../../models/song_model.dart';

abstract class MusicApiService {
  Future<List<SongModel>> searchSongs(String query);
  Future<String> getStreamUrl(String videoId);
  Future<SongModel> getVideoDetails(String videoId);
  Future<List<SongModel>> getTrendingMusic();
  Future<List<SongModel>> getArtistSongs(String artistName);
  Future<List<SongModel>> getRelatedSongs(String videoId);
}
