import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/models/song_model.dart';
import '../../data/datasources/remote/youtube_service.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final YouTubeService _youtubeService;
  
  final BehaviorSubject<SongModel?> _currentSongSubject = BehaviorSubject();
  final BehaviorSubject<List<SongModel>> _playlistSubject = BehaviorSubject.seeded([]);
  final BehaviorSubject<int> _currentIndexSubject = BehaviorSubject.seeded(0);
  final BehaviorSubject<bool> _isShuffleSubject = BehaviorSubject.seeded(false);
  final BehaviorSubject<LoopMode> _loopModeSubject = BehaviorSubject.seeded(LoopMode.off);

  AudioPlayerService(this._youtubeService);

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  Stream<SongModel?> get currentSongStream => _currentSongSubject.stream;
  SongModel? get currentSong => _currentSongSubject.value;
  Stream<List<SongModel>> get playlistStream => _playlistSubject.stream;
  List<SongModel> get playlist => _playlistSubject.value;
  
  Stream<Duration?> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;
  Stream<LoopMode> get loopModeStream => _loopModeSubject.stream;
  Stream<bool> get shuffleModeStream => _isShuffleSubject.stream;

  // Play a single song
  Future<void> playSong(SongModel song) async {
    try {
      _currentSongSubject.add(song);
      
      String? streamUrl = song.streamUrl;
      
      // If song is downloaded, use local path
      if (song.isDownloaded && song.localPath != null) {
        await _audioPlayer.setFilePath(song.localPath!);
      } else {
        // Get stream URL from YouTube
        streamUrl ??= await _youtubeService.getStreamUrl(song.id);
        
        // Try with MediaItem for background playback, fallback to simple URL
        try {
          await _audioPlayer.setAudioSource(
            AudioSource.uri(
              Uri.parse(streamUrl),
              tag: MediaItem(
                id: song.id,
                title: song.title,
                artist: song.artist,
                duration: song.duration,
                artUri: Uri.parse(song.thumbnailUrl),
              ),
            ),
          );
        } catch (e) {
          // Fallback: just use URL without MediaItem (no background notification)
          await _audioPlayer.setUrl(streamUrl);
        }
      }
      
      await _audioPlayer.play();
    } catch (e) {
      throw Exception('Failed to play song: $e');
    }
  }

  // Play a playlist
  Future<void> playPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;
    
    _playlistSubject.add(songs);
    _currentIndexSubject.add(startIndex);
    
    await playSong(songs[startIndex]);
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> next() async {
    final playlist = _playlistSubject.value;
    if (playlist.isEmpty) return;
    
    int nextIndex = _currentIndexSubject.value + 1;
    
    if (_isShuffleSubject.value) {
      nextIndex = DateTime.now().millisecondsSinceEpoch % playlist.length;
    } else if (nextIndex >= playlist.length) {
      if (_loopModeSubject.value == LoopMode.all) {
        nextIndex = 0;
      } else {
        return;
      }
    }
    
    _currentIndexSubject.add(nextIndex);
    await playSong(playlist[nextIndex]);
  }

  Future<void> previous() async {
    final playlist = _playlistSubject.value;
    if (playlist.isEmpty) return;
    
    if (_audioPlayer.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    
    int prevIndex = _currentIndexSubject.value - 1;
    
    if (prevIndex < 0) {
      if (_loopModeSubject.value == LoopMode.all) {
        prevIndex = playlist.length - 1;
      } else {
        await seek(Duration.zero);
        return;
      }
    }
    
    _currentIndexSubject.add(prevIndex);
    await playSong(playlist[prevIndex]);
  }

  void toggleShuffle() {
    _isShuffleSubject.add(!_isShuffleSubject.value);
  }

  void toggleLoopMode() {
    final currentMode = _loopModeSubject.value;
    LoopMode newMode;
    
    switch (currentMode) {
      case LoopMode.off:
        newMode = LoopMode.all;
        break;
      case LoopMode.all:
        newMode = LoopMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        newMode = LoopMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
    
    _loopModeSubject.add(newMode);
  }

  void setupListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        next();
      }
    });
  }

  void dispose() {
    _audioPlayer.dispose();
    _currentSongSubject.close();
    _playlistSubject.close();
    _currentIndexSubject.close();
    _isShuffleSubject.close();
    _loopModeSubject.close();
  }
}
