class AppConstants {
  // App Info
  static const String appName = 'Music Streaming';
  static const String appVersion = '1.0.0';
  
  // Theme Colors
  static const int primaryRedValue = 0xFFDC143C;
  static const int darkRedValue = 0xFF8B0000;
  static const int backgroundColorValue = 0xFF000000;
  static const int surfaceColorValue = 0xFF1A1A1A;
  
  // Audio Settings
  static const int defaultBufferDuration = 5000; // milliseconds
  static const int maxCacheSize = 100; // MB
  
  // Download Settings
  static const String downloadFolderName = 'music_downloads';
  static const String thumbnailFolderName = 'thumbnails';
  
  // Search Settings
  static const int searchDebounceMilliseconds = 500;
  static const int maxSearchResults = 20;
  
  // UI Settings
  static const double miniPlayerHeight = 70;
  static const double bottomNavHeight = 80;
}
