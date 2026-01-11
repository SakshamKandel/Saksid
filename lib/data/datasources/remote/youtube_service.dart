import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../models/song_model.dart';

class YouTubeService {
  final YoutubeExplode _yt = YoutubeExplode();
  final http.Client _httpClient = http.Client();

  // Popular songs to show on home screen
  static const List<Map<String, String>> popularSongs = [
    {
      'title': 'Perfect',
      'artist': 'Ed Sheeran',
      'query': 'Ed Sheeran Perfect Official'
    },
    {
      'title': 'Shape of You',
      'artist': 'Ed Sheeran',
      'query': 'Ed Sheeran Shape of You'
    },
    {
      'title': 'Blinding Lights',
      'artist': 'The Weeknd',
      'query': 'The Weeknd Blinding Lights'
    },
    {
      'title': 'Someone Like You',
      'artist': 'Adele',
      'query': 'Adele Someone Like You'
    },
    {
      'title': 'Stay',
      'artist': 'Kid Laroi & Justin Bieber',
      'query': 'Kid Laroi Stay'
    },
    {
      'title': 'Levitating',
      'artist': 'Dua Lipa',
      'query': 'Dua Lipa Levitating'
    },
    {
      'title': 'Heat Waves',
      'artist': 'Glass Animals',
      'query': 'Glass Animals Heat Waves'
    },
    {
      'title': 'Peaches',
      'artist': 'Justin Bieber',
      'query': 'Justin Bieber Peaches'
    },
    {
      'title': 'drivers license',
      'artist': 'Olivia Rodrigo',
      'query': 'Olivia Rodrigo drivers license'
    },
    {
      'title': 'Bad Guy',
      'artist': 'Billie Eilish',
      'query': 'Billie Eilish Bad Guy'
    },
    {
      'title': 'Senorita',
      'artist': 'Shawn Mendes & Camila',
      'query': 'Shawn Mendes Senorita'
    },
    {
      'title': 'Dance Monkey',
      'artist': 'Tones and I',
      'query': 'Tones and I Dance Monkey'
    },
    {
      'title': 'Watermelon Sugar',
      'artist': 'Harry Styles',
      'query': 'Harry Styles Watermelon Sugar'
    },
    {'title': 'Dynamite', 'artist': 'BTS', 'query': 'BTS Dynamite'},
    {
      'title': 'positions',
      'artist': 'Ariana Grande',
      'query': 'Ariana Grande positions'
    },
  ];

  // Search for songs
  Future<List<SongModel>> searchSongs(String query) async {
    // On web, use Piped API (YouTube API doesn't work due to CORS)
    if (kIsWeb) {
      return _searchFromPiped(query);
    }

    try {
      debugPrint(
          'YouTubeService: Using youtube_explode_dart for search: $query');
      final searchResults = await _yt.search.search(query).timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('YouTube search timeout'),
          );
      final List<SongModel> songs = [];

      for (var video in searchResults.take(20)) {
        songs.add(SongModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          thumbnailUrl: video.thumbnails.mediumResUrl,
          highResThumbnail: video.thumbnails.highResUrl,
          duration: video.duration ?? Duration.zero,
        ));
      }

      return songs;
    } catch (e) {
      debugPrint('YouTubeService: Search failed, using Piped fallback: $e');
      // Fallback to Piped API on error
      return _searchFromPiped(query);
    }
  }

  // Search using Piped API (works on web due to CORS headers)
  Future<List<SongModel>> _searchFromPiped(String query) async {
    final pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://api.piped.yt',
      'https://pipedapi.r4fo.com',
    ];

    for (final instance in pipedInstances) {
      try {
        final uri = Uri.parse(
            '$instance/search?q=${Uri.encodeComponent(query)}&filter=music_songs');
        final response = await _httpClient.get(uri).timeout(
              const Duration(seconds: 6),
              onTimeout: () => throw Exception('Piped search timeout'),
            );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final items = data['items'] as List?;

          if (items != null && items.isNotEmpty) {
            final List<SongModel> songs = [];

            for (var item in items.take(20)) {
              // Extract video ID from URL
              final url = item['url'] as String?;
              if (url == null) continue;

              final videoId = url.replaceFirst('/watch?v=', '');

              songs.add(SongModel(
                id: videoId,
                title: item['title'] ?? 'Unknown',
                artist: item['uploaderName'] ?? 'Unknown Artist',
                thumbnailUrl: item['thumbnail'] ?? '',
                highResThumbnail: item['thumbnail'] ?? '',
                duration: Duration(seconds: item['duration'] ?? 0),
              ));
            }

            return songs;
          }
        }
      } catch (e) {
        debugPrint('YouTubeService: Piped instance $instance failed: $e');
        continue; // Try next instance
      }
    }

    debugPrint(
        'YouTubeService: All Piped instances failed, returning sample songs');
    return _getSampleSongs();
  }

  // Get stream URL for a song with retry logic
  Future<String> getStreamUrl(String videoId) async {
    debugPrint('YouTubeService: Getting stream URL for video: $videoId');

    // On web, use Piped API (CORS-friendly proxy)
    if (kIsWeb) {
      debugPrint('YouTubeService: Using Piped API (web platform)');
      return _getStreamUrlFromPiped(videoId);
    }

    // Try up to 3 times with increasing delays
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        debugPrint(
            'YouTubeService: Attempt $attempt - Fetching manifest from YouTube using youtube_explode_dart...');
        final manifest =
            await _yt.videos.streamsClient.getManifest(videoId).timeout(
                  const Duration(seconds: 25),
                  onTimeout: () => throw Exception('YouTube manifest timeout'),
                );

        // Get audio only stream (best quality)
        final audioStreams = manifest.audioOnly;
        if (audioStreams.isEmpty) {
          debugPrint(
              'YouTubeService: No audio streams found, trying Piped fallback');
          return _getStreamUrlFromPiped(videoId);
        }

        final audio = audioStreams.withHighestBitrate();
        final url = audio.url.toString();
        debugPrint(
            'YouTubeService: Got stream URL (bitrate: ${audio.bitrate})');
        return url;
      } catch (e) {
        debugPrint('YouTubeService: Attempt $attempt failed: $e');
        if (attempt < 3) {
          // Wait before retrying with exponential backoff
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        debugPrint(
            'YouTubeService: All attempts failed, trying Piped API fallback...');
        // Fallback to Piped API on final error
        return _getStreamUrlFromPiped(videoId);
      }
    }
    // Should not reach here, but fallback just in case
    return _getStreamUrlFromPiped(videoId);
  }

  // Get stream URL from Piped API (works on web due to CORS headers)
  Future<String> _getStreamUrlFromPiped(String videoId) async {
    debugPrint('YouTubeService: Attempting Piped API for video: $videoId');

    // List of Piped API instances that support CORS
    final pipedInstances = [
      'https://pipedapi.kavin.rocks',
      'https://api.piped.yt',
      'https://pipedapi.r4fo.com',
    ];

    for (final instance in pipedInstances) {
      try {
        debugPrint('YouTubeService: Trying Piped instance: $instance');
        final uri = Uri.parse('$instance/streams/$videoId');
        final response = await _httpClient.get(uri).timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw Exception('Piped API timeout'),
            );

        debugPrint(
            'YouTubeService: Piped response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final audioStreams = data['audioStreams'] as List?;

          if (audioStreams != null && audioStreams.isNotEmpty) {
            // Get highest quality audio stream
            audioStreams.sort(
                (a, b) => (b['bitrate'] ?? 0).compareTo(a['bitrate'] ?? 0));
            final url = audioStreams.first['url'] as String;
            debugPrint('YouTubeService: Got Piped stream URL successfully');
            return url;
          } else {
            debugPrint('YouTubeService: No audio streams in Piped response');
          }
        }
      } catch (e) {
        debugPrint('YouTubeService: Piped instance $instance failed: $e');
        continue; // Try next instance
      }
    }

    debugPrint('YouTubeService: All Piped instances failed');
    throw Exception('Failed to get stream URL from Piped API');
  }

  // Get audio stream info for download
  Future<AudioStreamInfo> getAudioStreamInfo(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      return manifest.audioOnly.withHighestBitrate();
    } catch (e) {
      throw Exception('Failed to get audio stream: $e');
    }
  }

  // Get video details
  Future<SongModel> getVideoDetails(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      final streamUrl = await getStreamUrl(videoId);

      return SongModel(
        id: video.id.value,
        title: video.title,
        artist: video.author,
        thumbnailUrl: video.thumbnails.mediumResUrl,
        highResThumbnail: video.thumbnails.maxResUrl,
        duration: video.duration ?? Duration.zero,
        streamUrl: streamUrl,
      );
    } catch (e) {
      throw Exception('Failed to get video details: $e');
    }
  }

  // Get trending/popular music
  Future<List<SongModel>> getTrendingMusic() async {
    debugPrint('YouTubeService: Getting trending music...');

    // On web, use Piped API (YouTube API doesn't work due to CORS)
    if (kIsWeb) {
      return _getTrendingFromPiped();
    }

    try {
      final List<SongModel> songs = [];
      int failureCount = 0;
      const maxFailures = 3; // If 3 consecutive failures, switch to fallback

      for (var songData in popularSongs) {
        // If too many failures, switch to sample songs immediately
        if (failureCount >= maxFailures) {
          debugPrint('YouTubeService: Too many failures, using sample songs');
          return _getSampleSongs();
        }

        try {
          debugPrint(
              'YouTubeService: Searching for ${songData['title']} via youtube_explode_dart');
          final results = await _yt.search.search(songData['query']!).timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw Exception('Search timeout'),
              );
          if (results.isNotEmpty) {
            final video = results.first;
            songs.add(SongModel(
              id: video.id.value,
              title: songData['title']!,
              artist: songData['artist']!,
              thumbnailUrl: video.thumbnails.mediumResUrl,
              highResThumbnail: video.thumbnails.highResUrl,
              duration: video.duration ?? Duration.zero,
            ));
            failureCount = 0; // Reset on success
          }
        } catch (e) {
          debugPrint('YouTubeService: Failed to load ${songData['title']}: $e');
          failureCount++;
          continue;
        }
      }

      // If API failed but we have no songs, use sample songs directly
      if (songs.isEmpty) {
        debugPrint('YouTubeService: No songs loaded, returning sample songs');
        return _getSampleSongs();
      }

      debugPrint('YouTubeService: Loaded ${songs.length} trending songs');
      return songs;
    } catch (e) {
      debugPrint('YouTubeService: getTrendingMusic failed: $e');
      // Return sample songs when YouTube API fails
      return _getSampleSongs();
    }
  }

  // Get trending music from Piped API
  Future<List<SongModel>> _getTrendingFromPiped() async {
    debugPrint('YouTubeService: Getting trending from Piped API...');
    final List<SongModel> allSongs = [];
    int failureCount = 0;
    const maxFailures = 3;

    // Search for each popular song using Piped API
    for (var songData in popularSongs.take(12)) {
      // If too many failures, return sample songs
      if (failureCount >= maxFailures) {
        debugPrint(
            'YouTubeService: Piped API has too many failures, using sample songs');
        return _getSampleSongs();
      }

      try {
        final songs = await _searchFromPiped(songData['query']!);
        if (songs.isNotEmpty) {
          // Update song with correct title/artist from our list
          final song = songs.first.copyWith(
            title: songData['title'],
            artist: songData['artist'],
          );
          allSongs.add(song);
          failureCount = 0; // Reset on success
        }
      } catch (e) {
        debugPrint(
            'YouTubeService: Piped search failed for ${songData['title']}: $e');
        failureCount++;
        continue; // Skip if this search fails
      }

      // Small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // If no songs found from API, return sample data as last resort
    if (allSongs.isEmpty) {
      debugPrint('YouTubeService: No songs from Piped, returning sample songs');
      return _getSampleSongs();
    }

    debugPrint('YouTubeService: Loaded ${allSongs.length} songs from Piped');
    return allSongs;
  }

  // Sample songs for fallback (when API fails in web) - using REAL YouTube video IDs
  List<SongModel> _getSampleSongs() {
    return [
      SongModel(
        id: '2Vv-BfVoq4g', // Real YouTube ID for Perfect
        title: 'Perfect',
        artist: 'Ed Sheeran',
        thumbnailUrl: 'https://i.ytimg.com/vi/2Vv-BfVoq4g/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/2Vv-BfVoq4g/hqdefault.jpg',
        duration: const Duration(minutes: 4, seconds: 23),
      ),
      SongModel(
        id: 'JGwWNGJdvx8', // Real YouTube ID for Shape of You
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        thumbnailUrl: 'https://i.ytimg.com/vi/JGwWNGJdvx8/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/JGwWNGJdvx8/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 53),
      ),
      SongModel(
        id: '4NRXx6U8ABQ', // Real YouTube ID for Blinding Lights
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        thumbnailUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 22),
      ),
      SongModel(
        id: 'hLQl3WQQoQ0', // Real YouTube ID for Someone Like You
        title: 'Someone Like You',
        artist: 'Adele',
        thumbnailUrl: 'https://i.ytimg.com/vi/hLQl3WQQoQ0/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/hLQl3WQQoQ0/hqdefault.jpg',
        duration: const Duration(minutes: 4, seconds: 45),
      ),
      SongModel(
        id: 'kTJczUoc26U', // Real YouTube ID for Stay
        title: 'Stay',
        artist: 'Kid Laroi & Justin Bieber',
        thumbnailUrl: 'https://i.ytimg.com/vi/kTJczUoc26U/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/kTJczUoc26U/hqdefault.jpg',
        duration: const Duration(minutes: 2, seconds: 21),
      ),
      SongModel(
        id: 'TUVcZfQe-Kw', // Real YouTube ID for Levitating
        title: 'Levitating',
        artist: 'Dua Lipa',
        thumbnailUrl: 'https://i.ytimg.com/vi/TUVcZfQe-Kw/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/TUVcZfQe-Kw/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 23),
      ),
      SongModel(
        id: 'mRD0-GxqHVo', // Real YouTube ID for Heat Waves
        title: 'Heat Waves',
        artist: 'Glass Animals',
        thumbnailUrl: 'https://i.ytimg.com/vi/mRD0-GxqHVo/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/mRD0-GxqHVo/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 58),
      ),
      SongModel(
        id: 'tQ0yjYUFKAE', // Real YouTube ID for Peaches
        title: 'Peaches',
        artist: 'Justin Bieber',
        thumbnailUrl: 'https://i.ytimg.com/vi/tQ0yjYUFKAE/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/tQ0yjYUFKAE/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 18),
      ),
      SongModel(
        id: 'ZmDBbnmKpqQ', // Real YouTube ID for drivers license
        title: 'drivers license',
        artist: 'Olivia Rodrigo',
        thumbnailUrl: 'https://i.ytimg.com/vi/ZmDBbnmKpqQ/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/ZmDBbnmKpqQ/hqdefault.jpg',
        duration: const Duration(minutes: 4, seconds: 2),
      ),
      SongModel(
        id: 'DyDfgMOUjCI', // Real YouTube ID for Bad Guy
        title: 'Bad Guy',
        artist: 'Billie Eilish',
        thumbnailUrl: 'https://i.ytimg.com/vi/DyDfgMOUjCI/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/DyDfgMOUjCI/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 14),
      ),
      SongModel(
        id: 'Pkh8UtuejGw', // Real YouTube ID for Senorita
        title: 'Senorita',
        artist: 'Shawn Mendes & Camila',
        thumbnailUrl: 'https://i.ytimg.com/vi/Pkh8UtuejGw/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/Pkh8UtuejGw/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 11),
      ),
      SongModel(
        id: 'q0hyYWKXF0Q', // Real YouTube ID for Dance Monkey
        title: 'Dance Monkey',
        artist: 'Tones and I',
        thumbnailUrl: 'https://i.ytimg.com/vi/q0hyYWKXF0Q/mqdefault.jpg',
        highResThumbnail: 'https://i.ytimg.com/vi/q0hyYWKXF0Q/hqdefault.jpg',
        duration: const Duration(minutes: 3, seconds: 29),
      ),
    ];
  }

  // Get songs by artist
  Future<List<SongModel>> getArtistSongs(String artistName) async {
    try {
      final results = await _yt.search.search(artistName);
      final List<SongModel> songs = [];

      for (var video in results.take(10)) {
        songs.add(SongModel(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          thumbnailUrl: video.thumbnails.mediumResUrl,
          highResThumbnail: video.thumbnails.highResUrl,
          duration: video.duration ?? Duration.zero,
        ));
      }
      return songs;
    } catch (e) {
      throw Exception('Failed to get artist songs: $e');
    }
  }

  // Get related songs
  Future<List<SongModel>> getRelatedSongs(String videoId) async {
    try {
      final video = await _yt.videos.get(videoId);
      final relatedVideos = (await _yt.videos.getRelatedVideos(video)) ?? [];
      final List<SongModel> songs = [];

      for (var related in relatedVideos.take(10)) {
        songs.add(SongModel(
          id: related.id.value,
          title: related.title,
          artist: related.author,
          thumbnailUrl: related.thumbnails.mediumResUrl,
          highResThumbnail: related.thumbnails.highResUrl,
          duration: related.duration ?? Duration.zero,
        ));
      }
      return songs;
    } catch (e) {
      // Fallback to search if related videos fail
      try {
        final video = await _yt.videos.get(videoId);
        return searchSongs(video.author);
      } catch (_) {
        return [];
      }
    }
  }

  void dispose() {
    _yt.close();
  }
}
