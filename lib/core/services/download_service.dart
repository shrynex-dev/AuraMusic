import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:id3/id3.dart';
import '../../shared/models/song.dart';
import 'database_service.dart';
import '../data_sources/newpipe_data_source.dart';

enum DownloadLocation { external, internal }

class DownloadService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  static const String _downloadLocationKey = 'download_location';

  static Future<DownloadLocation> getDownloadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final location = prefs.getString(_downloadLocationKey);
    return location == 'external'
        ? DownloadLocation.external
        : DownloadLocation.internal;
  }

  static Future<void> setDownloadLocation(DownloadLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _downloadLocationKey,
      location == DownloadLocation.external ? 'external' : 'internal',
    );
  }

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      // Android 13+ - request manage external storage for full access
      final manageStatus = await Permission.manageExternalStorage.request();
      if (manageStatus.isGranted) return true;

      // Fallback to media permissions
      final audioStatus = await Permission.audio.request();
      return audioStatus.isGranted;
    } else if (androidInfo.version.sdkInt >= 30) {
      // Android 11-12 - request manage external storage
      final manageStatus = await Permission.manageExternalStorage.request();
      return manageStatus.isGranted;
    } else {
      // Below Android 11 - request storage permission
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  static Future<List<String>> getAllDownloadPaths() async {
    final paths = <String>[];

    // External storage paths
    if (Platform.isAndroid) {
      final externalPaths = [
        '/storage/emulated/0/Music/AuraMusic',
        '/storage/emulated/0/Download/AuraMusic',
        '/storage/emulated/0/AuraMusic',
      ];

      for (final path in externalPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          paths.add(path);
        }
      }
    }

    // Internal storage path
    final directory = await getApplicationDocumentsDirectory();
    final internalPath = '${directory.path}/AuraMusic';
    final internalDir = Directory(internalPath);
    if (await internalDir.exists()) {
      paths.add(internalPath);
    }

    return paths;
  }

  static Future<String> _getDownloadPath() async {
    final location = await getDownloadLocation();

    if (location == DownloadLocation.external && Platform.isAndroid) {
      try {
        // Try multiple possible paths for external storage
        final possiblePaths = [
          '/storage/emulated/0/Music/AuraMusic',
          '/storage/emulated/0/Download/AuraMusic',
          '/storage/emulated/0/AuraMusic',
        ];

        for (final path in possiblePaths) {
          try {
            final downloadDir = Directory(path);
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            // Test write permission
            final testFile = File('${downloadDir.path}/.test');
            await testFile.writeAsString('test');
            await testFile.delete();
            return downloadDir.path;
          } catch (e) {
            continue;
          }
        }
      } catch (_) {
        // Fallback to internal storage
      }
    }

    // Fallback to internal storage
    final directory = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${directory.path}/AuraMusic');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }

    return downloadDir.path;
  }

  static Future<bool> downloadSong(
    Song song, {
    Function(double)? onProgress,
  }) async {
    try {
      String? streamUrl = song.streamUrl;

      // Fetch fresh stream URL for YouTube songs
      if (song.youtubeId != null) {
        streamUrl = await NewPipeDataSource().getStreamUrl(song.youtubeId!, {});
      }

      if (streamUrl == null) return false;

      final downloadPath = await _getDownloadPath();
      final fileName = '${song.id}.mp3';
      final filePath = '$downloadPath/$fileName';

      await _dio.download(
        streamUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      song.isDownloaded = true;
      song.localPath = filePath;
      await DatabaseService.saveSong(song);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteSong(Song song) async {
    if (song.localPath == null) return false;

    try {
      final file = File(song.localPath!);
      if (await file.exists()) {
        await file.delete();
      }

      song.isDownloaded = false;
      song.localPath = null;
      await DatabaseService.saveSong(song);

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isDownloaded(Song song) async {
    if (song.localPath == null) return false;
    final file = File(song.localPath!);
    return await file.exists();
  }

  static Future<List<Song>> getAllDownloadedSongs() async {
    final dbSongs = await DatabaseService.getDownloadedSongs();
    final scannedSongs = <Song>[];
    final paths = await getAllDownloadPaths();

    for (final path in paths) {
      try {
        final dir = Directory(path);
        if (!await dir.exists()) continue;

        await for (final entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.mp3')) {
            final fileName = entity.path.split('/').last.replaceAll('.mp3', '');

            final dbSong = dbSongs.firstWhere(
              (s) => s.id == fileName,
              orElse: () =>
                  Song(
                      id: fileName,
                      songId: fileName,
                      title: fileName.replaceAll('_', ' '),
                      artist: 'Unknown',
                      streamUrl: entity.path,
                      source: 'local',
                    )
                    ..isDownloaded = true
                    ..localPath = entity.path,
            );

            if (dbSong.source == 'local') {
              try {
                final bytes = await entity.readAsBytes();
                final mp3 = MP3Instance(bytes);
                if (mp3.parseTagsSync()) {
                  final tags = mp3.getMetaTags();
                  dbSong.title = tags?['Title'] ?? dbSong.title;
                  dbSong.artist = tags?['Artist'] ?? dbSong.artist;
                  dbSong.album = tags?['Album'];
                }
              } catch (_) {}
            }

            if (!scannedSongs.any((s) => s.id == dbSong.id)) {
              scannedSongs.add(dbSong);
            }
          }
        }
      } catch (_) {
        // Skip scanning errors
      }
    }

    return scannedSongs.isEmpty ? dbSongs : scannedSongs;
  }
}
