# Setup Guide - Music Streaming App

## Step-by-Step Setup Instructions

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

### 2. Generate Required Files

The app uses Hive for local storage which requires code generation:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate the `song_model.g.dart` file needed for Hive type adapters.

### 3. Android Configuration

The AndroidManifest.xml is already configured with necessary permissions:
- Internet access
- Foreground service for background audio
- Wake lock for continuous playback
- Storage permissions for downloads

### 4. iOS Configuration (if targeting iOS)

Add the following to `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### 5. Run the App

```bash
# For Android
flutter run

# For specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

## Project Features

### 🎵 Music Streaming
- Search and play songs from YouTube
- High-quality audio streaming
- Background playback support

### 📥 Downloads
- Download songs for offline playback
- Track download progress
- Manage downloaded songs

### 🎨 UI Features
- Black and Red theme
- Mini player for quick controls
- Full-screen player with album art
- Search functionality
- Downloads management

### 🎧 Playback Controls
- Play/Pause
- Next/Previous track
- Shuffle mode
- Repeat modes (off, all, one)
- Seek functionality
- Lock screen controls

## Architecture Overview

```
┌─────────────────────────────────────────┐
│           Presentation Layer             │
│  (Screens, Widgets, Controllers)         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│           Service Layer                  │
│  (Audio Service, Download Service)       │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│            Data Layer                    │
│  (YouTube Service, Models, Storage)      │
└──────────────────────────────────────────┘
```

## Key Technologies

1. **youtube_explode_dart**: Extracts audio streams from YouTube
2. **just_audio**: Handles audio playback
3. **audio_service**: Enables background playback
4. **provider**: State management
5. **hive**: Local database for downloads
6. **dio**: HTTP client for downloads

## Troubleshooting

### Build Runner Issues
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Audio Not Playing
- Check internet connection
- Verify YouTube video is available
- Check device volume settings

### Download Issues
- Verify storage permissions
- Check available storage space
- Ensure internet connection is stable

### Background Playback Not Working
- Verify audio_service is properly configured
- Check AndroidManifest.xml permissions
- For iOS, verify Info.plist configuration

## Development Tips

### Hot Reload
```bash
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart
```

### Debug Mode
```bash
flutter run --debug
```

### Release Build
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## Popular Songs Included

The app comes pre-configured with popular songs:
- Perfect - Ed Sheeran
- Shape of You - Ed Sheeran
- Blinding Lights - The Weeknd
- Someone Like You - Adele
- Stay - Kid Laroi & Justin Bieber
- And many more...

## Performance Optimization

1. **Image Caching**: Uses `cached_network_image` for efficient image loading
2. **Audio Streaming**: Streams audio instead of downloading entire files
3. **Background Processing**: Offloads heavy tasks to background threads
4. **State Management**: Efficient state updates with Provider

## Security & Privacy

- No user data collection
- No analytics tracking
- Local storage only for downloads
- No external servers (except YouTube)

## Educational Purpose Disclaimer

This application is created for educational purposes to demonstrate:
- Flutter mobile app development
- Audio streaming implementation
- State management patterns
- Clean architecture principles
- Background services in Flutter

**Important**: Users must comply with YouTube's Terms of Service and copyright laws.

## Next Steps

1. Run `flutter pub get`
2. Run `flutter pub run build_runner build`
3. Connect a device or start an emulator
4. Run `flutter run`
5. Enjoy your music streaming app!

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Flutter documentation
3. Check package documentation for specific dependencies

Happy coding! 🎵
