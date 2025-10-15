# NewPipe Extractor Setup Guide

## Overview
This guide explains how the NewPipe Extractor integration was implemented for AuraMusic to enable YouTube music streaming via a native Android bridge.

## Architecture

### 1. Native Android Layer (Kotlin)

**Files Modified/Created:**
- `android/app/src/main/kotlin/com/shrynex/auramusic/MainActivity.kt`
- `android/app/src/main/kotlin/com/shrynex/auramusic/DownloaderImpl.kt`
- `android/app/build.gradle.kts`
- `android/build.gradle.kts`

**MainActivity.kt Changes:**
- Added NewPipe MethodChannel: `com.myapp/newpipe_data_source`
- Initialized NewPipe Extractor with custom downloader
- Implemented two methods:
  - `search`: Searches YouTube and returns song metadata
  - `getStreamUrl`: Extracts best audio-only stream URL from video ID
- Used Kotlin coroutines for background threading

**DownloaderImpl.kt:**
- Custom HTTP downloader implementation required by NewPipe Extractor
- Handles HTTP requests with proper headers and error handling
- Singleton pattern for efficient resource usage

### 2. Dependencies Added

**android/build.gradle.kts:**
```kotlin
maven { url = uri("https://jitpack.io") }
```

**android/app/build.gradle.kts:**
```kotlin
implementation("com.github.TeamNewPipe:NewPipeExtractor:v0.24.2")
implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
```

### 3. Dart Layer

**Files Created:**
- `lib/core/data_sources/music_data_source.dart` - Abstract interface
- `lib/core/data_sources/newpipe_data_source.dart` - NewPipe implementation
- `lib/core/data_sources/saavn_archive_data_source.dart` - Alternative source
- `lib/core/providers/data_source_provider.dart` - State management
- `lib/features/settings/pages/data_source_settings_page.dart` - UI switcher

**NewPipeDataSource:**
- Communicates with native code via MethodChannel
- Converts native results to Song model
- Handles errors gracefully

## How It Works

1. **Search Flow:**
   - User enters search query in Flutter UI
   - Dart calls `NewPipeDataSource.search(query)`
   - MethodChannel sends request to native Android
   - Native code uses NewPipe Extractor to search YouTube
   - Results parsed and sent back to Dart
   - Converted to `List<Song>` and displayed

2. **Stream URL Flow:**
   - User selects a song to play
   - Dart calls `getStreamUrl(id, metadata)`
   - MethodChannel requests stream URL from native code
   - Native code extracts best audio stream using NewPipe
   - Direct stream URL returned to Dart
   - Audio player uses URL for playback

## Key Features

- **Background Threading:** All network operations run on IO dispatcher
- **Error Handling:** Comprehensive try-catch blocks on both layers
- **Best Quality:** Automatically selects highest bitrate audio stream
- **No API Keys:** NewPipe Extractor works without YouTube API keys
- **Dual Source:** Seamlessly switch between NewPipe and JioSaavn+Archive.org

## Usage

1. **Initialize Provider in main.dart:**
```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DataSourceProvider(),
      child: MyApp(),
    ),
  );
}
```

2. **Access in any widget:**
```dart
final dataSource = Provider.of<DataSourceProvider>(context).activeDataSource;
final results = await dataSource.search('query');
```

3. **Switch sources in settings:**
```dart
provider.setDataSource(DataSourceType.newPipe);
```

## Testing

1. Build the Android app: `flutter build apk`
2. Install on device: `flutter install`
3. Navigate to Data Source Settings
4. Select "NewPipe (YouTube)"
5. Search for music - results should come from YouTube
6. Play a song - audio should stream directly

## Troubleshooting

**Build Errors:**
- Ensure JitPack repository is added to `android/build.gradle.kts`
- Check Kotlin version compatibility (requires 1.7+)
- Clean build: `flutter clean && flutter pub get`

**Runtime Errors:**
- Check Android logs: `adb logcat | grep NewPipe`
- Verify internet permissions in AndroidManifest.xml
- Ensure NewPipe initialization happens before first use

**No Results:**
- NewPipe Extractor may need updates if YouTube changes
- Check if device has internet connection
- Verify MethodChannel name matches on both sides

## Future Enhancements

- Cache search results
- Support for playlists and albums
- Video quality selection
- Download support via NewPipe
- SponsorBlock integration
