# Music Streaming App

A Flutter-based music streaming application for educational purposes with YouTube integration. Features a sleek black and red theme inspired by modern music apps.

## Features

- 🎵 Stream music from YouTube
- 📥 Download songs for offline playback
- 🎨 Black & Red themed UI
- 🔄 Background audio playback
- 🔀 Shuffle and repeat modes
- 🔍 Search functionality
- 📱 Lock screen controls
- 🎧 Mini player
- 💾 Offline downloads management

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── config/
│   └── theme/
│       └── app_theme.dart
├── core/
├── data/
│   ├── models/
│   │   └── song_model.dart
│   ├── datasources/
│   │   └── remote/
│   │       └── youtube_service.dart
├── services/
│   ├── audio/
│   │   └── audio_player_service.dart
│   └── download/
│       └── download_service.dart
├── presentation/
│   ├── screens/
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── search/
│   │   │   └── search_screen.dart
│   │   ├── player/
│   │   │   ├── player_screen.dart
│   │   │   └── mini_player.dart
│   │   └── downloads/
│   │       └── downloads_screen.dart
│   └── controllers/
│       └── player_controller.dart
└── di/
    └── injection_container.dart
```

## Setup Instructions

### Prerequisites

- Flutter SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK for Android development
- Xcode for iOS development (Mac only)

### Installation

1. Clone the repository
2. Install dependencies:
```bash
flutter pub get
```

3. Generate Hive adapters:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

## Key Dependencies

- `just_audio` - Audio playback
- `audio_service` - Background audio
- `youtube_explode_dart` - YouTube data extraction
- `dio` - HTTP client for downloads
- `hive` - Local database
- `provider` - State management
- `cached_network_image` - Image caching

## Architecture

The app follows a clean architecture pattern with:

- **Presentation Layer**: UI components and controllers
- **Service Layer**: Business logic (audio, downloads)
- **Data Layer**: Models and data sources
- **Dependency Injection**: GetIt for service locator

## How It Works

1. **YouTube Integration**: Uses `youtube_explode_dart` to search and extract audio streams
2. **Audio Streaming**: `just_audio` handles playback with background support
3. **Downloads**: `dio` downloads audio files to local storage
4. **State Management**: Provider pattern for reactive UI updates

## Features Implementation

### Streaming
- Extracts audio-only streams from YouTube
- Supports background playback
- Lock screen controls via `audio_service`

### Downloads
- Downloads highest quality audio
- Stores in app documents directory
- Progress tracking
- Offline playback support

### UI/UX
- Black (#000000) and Red (#DC143C) theme
- Material Design components
- Smooth animations
- Responsive layout

## Permissions

### Android
- INTERNET - Stream and download music
- FOREGROUND_SERVICE - Background playback
- WAKE_LOCK - Keep playing when screen off
- WRITE_EXTERNAL_STORAGE - Save downloads
- READ_EXTERNAL_STORAGE - Access downloads

## Educational Purpose

This app is created for educational purposes only. It demonstrates:
- Flutter app development
- Audio streaming implementation
- Background services
- State management
- Clean architecture
- YouTube API integration

## Disclaimer

This application is for educational purposes only. Users are responsible for complying with YouTube's Terms of Service and copyright laws. Do not use this app to infringe on copyrights or violate any terms of service.

## License

This project is for educational purposes only.
