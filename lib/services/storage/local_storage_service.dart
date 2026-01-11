import 'package:shared_preferences/shared_preferences.dart';

enum AudioQuality { low, medium, high }

class LocalStorageService {
  static const String keyThemeMode = 'theme_mode';
  static const String keyAudioQuality = 'audio_quality';
  static const String keyAutoPlay = 'auto_play';
  static const String keyCrossfade = 'crossfade';
  static const String keyCrossfadeDuration = 'crossfade_duration';
  static const String keyNormalizeVolume = 'normalize_volume';
  static const String keyDownloadQuality = 'download_quality';
  static const String keyDownloadOverWifi = 'download_over_wifi';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Theme Mode
  String getThemeMode() {
    return _prefs.getString(keyThemeMode) ?? 'dark';
  }

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(keyThemeMode, mode);
  }

  // Audio Quality (streaming)
  AudioQuality getAudioQuality() {
    final value = _prefs.getString(keyAudioQuality) ?? 'high';
    return AudioQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AudioQuality.high,
    );
  }

  Future<void> setAudioQuality(AudioQuality quality) async {
    await _prefs.setString(keyAudioQuality, quality.name);
  }

  // Auto Play
  bool getAutoPlay() {
    return _prefs.getBool(keyAutoPlay) ?? true;
  }

  Future<void> setAutoPlay(bool value) async {
    await _prefs.setBool(keyAutoPlay, value);
  }

  // Crossfade
  bool getCrossfade() {
    return _prefs.getBool(keyCrossfade) ?? false;
  }

  Future<void> setCrossfade(bool value) async {
    await _prefs.setBool(keyCrossfade, value);
  }

  // Crossfade Duration (seconds)
  int getCrossfadeDuration() {
    return _prefs.getInt(keyCrossfadeDuration) ?? 5;
  }

  Future<void> setCrossfadeDuration(int seconds) async {
    await _prefs.setInt(keyCrossfadeDuration, seconds);
  }

  // Normalize Volume
  bool getNormalizeVolume() {
    return _prefs.getBool(keyNormalizeVolume) ?? false;
  }

  Future<void> setNormalizeVolume(bool value) async {
    await _prefs.setBool(keyNormalizeVolume, value);
  }

  // Download Quality
  AudioQuality getDownloadQuality() {
    final value = _prefs.getString(keyDownloadQuality) ?? 'high';
    return AudioQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AudioQuality.high,
    );
  }

  Future<void> setDownloadQuality(AudioQuality quality) async {
    await _prefs.setString(keyDownloadQuality, quality.name);
  }

  // Download over WiFi only
  bool getDownloadOverWifi() {
    return _prefs.getBool(keyDownloadOverWifi) ?? false;
  }

  Future<void> setDownloadOverWifi(bool value) async {
    await _prefs.setBool(keyDownloadOverWifi, value);
  }

  // Clear all settings
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
