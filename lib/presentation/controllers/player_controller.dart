import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/song_model.dart';
import '../../data/models/playlist_model.dart';
import '../../services/audio/audio_player_service.dart';
import '../../services/download/download_service.dart';
import '../../services/playlist/playlist_service.dart';

class PlayerController extends ChangeNotifier {
  final AudioPlayerService _audioService;
  final DownloadService _downloadService;
  final PlaylistService _playlistService;

  SongModel? _currentSong;
  List<SongModel> _playlist = [];
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  bool _isMiniPlayerVisible = false;

  PlayerController(this._audioService, this._downloadService, this._playlistService) {
    _initListeners();
  }

  // Getters
  SongModel? get currentSong => _currentSong;
  List<SongModel> get playlist => _playlist;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isShuffle => _isShuffle;
  LoopMode get loopMode => _loopMode;
  bool get isMiniPlayerVisible => _isMiniPlayerVisible;
  AudioPlayerService get audioService => _audioService;
  DownloadService get downloadService => _downloadService;
  PlaylistService get playlistService => _playlistService;

  void _initListeners() {
    _audioService.currentSongStream.listen((song) {
      _currentSong = song;
      _isMiniPlayerVisible = song != null;
      if (song != null) {
        // Add to recently played
        _playlistService.addToRecentlyPlayed(song);
      }
      notifyListeners();
    });

    _audioService.playingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _audioService.positionStream.listen((pos) {
      _position = pos ?? Duration.zero;
      notifyListeners();
    });

    _audioService.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      notifyListeners();
    });

    _audioService.loopModeStream.listen((mode) {
      _loopMode = mode;
      notifyListeners();
    });

    _audioService.shuffleModeStream.listen((shuffle) {
      _isShuffle = shuffle;
      notifyListeners();
    });

    _audioService.setupListeners();
  }

  Future<void> playSong(SongModel song) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _audioService.playSong(song);
    } catch (e) {
      debugPrint('PlayerController.playSong error: $e');
      // Don't rethrow - let the UI continue working
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> playPlaylist(List<SongModel> songs, {int startIndex = 0}) async {
    _playlist = songs;
    _isLoading = true;
    notifyListeners();

    try {
      await _audioService.playPlaylist(songs, startIndex: startIndex);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> togglePlayPause() async {
    await _audioService.togglePlayPause();
  }

  Future<void> next() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _audioService.next();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> previous() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _audioService.previous();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  void toggleShuffle() {
    _audioService.toggleShuffle();
  }

  void toggleLoopMode() {
    _audioService.toggleLoopMode();
  }

  Future<void> downloadSong(SongModel song) async {
    await _downloadService.downloadSong(song);
  }

  // Favorites
  bool isFavorite(String songId) {
    return _playlistService.isFavorite(songId);
  }

  Future<bool> toggleFavorite(SongModel song) async {
    final result = await _playlistService.toggleFavorite(song);
    notifyListeners();
    return result;
  }

  List<SongModel> getFavorites() {
    return _playlistService.getFavorites();
  }

  // Playlists
  List<PlaylistModel> getAllPlaylists() {
    return _playlistService.getAllPlaylists();
  }

  Future<PlaylistModel> createPlaylist(String name, {String? thumbnailUrl}) async {
    final playlist = await _playlistService.createPlaylist(name, thumbnailUrl: thumbnailUrl);
    notifyListeners();
    return playlist;
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _playlistService.deletePlaylist(playlistId);
    notifyListeners();
  }

  Future<PlaylistModel?> addSongToPlaylist(String playlistId, SongModel song) async {
    final playlist = await _playlistService.addSongToPlaylist(playlistId, song);
    notifyListeners();
    return playlist;
  }

  Future<PlaylistModel?> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = await _playlistService.removeSongFromPlaylist(playlistId, songId);
    notifyListeners();
    return playlist;
  }

  PlaylistModel? getPlaylist(String id) {
    return _playlistService.getPlaylist(id);
  }

  // Recently Played
  List<SongModel> getRecentlyPlayed({int limit = 20}) {
    return _playlistService.getRecentlyPlayed(limit: limit);
  }

  Future<void> clearRecentlyPlayed() async {
    await _playlistService.clearRecentlyPlayed();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _downloadService.dispose();
    super.dispose();
  }
}
