
import 'music_api_service.dart';
import '../../models/song_model.dart';

class PipedApiService implements MusicApiService {
  static const String baseUrl = 'https://pipedapi.kavin.rocks';

  @override
  Future<List<SongModel>> searchSongs(String query) async {
    // Implementation would go here calling Piped API
    return [];
  }

  @override
  Future<List<SongModel>> getArtistSongs(String artistName) async {
    return [];
  }

  @override
  Future<List<SongModel>> getRelatedSongs(String videoId) async {
    return [];
  }

  @override
  Future<String> getStreamUrl(String videoId) async {
    return '';
  }

  @override
  Future<List<SongModel>> getTrendingMusic() async {
    return [];
  }

  @override
  Future<SongModel> getVideoDetails(String videoId) async {
    throw UnimplementedError();
  }
}
