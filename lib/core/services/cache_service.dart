import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../shared/models/song.dart';

class CacheService {
  static final Dio _dio = Dio();
  static const int maxCacheSize = 20; // Keep last 20 songs for session
  static List<String> _cacheOrder = [];
  static final Map<String, String> _memoryCache = {}; // In-memory path cache

  static Future<String> _getCachePath() async {
    final directory = await getTemporaryDirectory();
    final cacheDir = Directory('${directory.path}/audio_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir.path;
  }

  static Future<String?> getCachedSongPath(Song song) async {
    if (song.streamUrl == null) return null;
    
    // Check memory cache first
    if (_memoryCache.containsKey(song.id)) {
      final cachedPath = _memoryCache[song.id]!;
      final file = File(cachedPath);
      if (await file.exists()) {
        _cacheOrder.remove(song.id);
        _cacheOrder.add(song.id);
        return cachedPath;
      } else {
        _memoryCache.remove(song.id);
      }
    }
    
    final cachePath = await _getCachePath();
    final fileName = '${song.id}_cache.mp3';
    final filePath = '$cachePath/$fileName';
    final file = File(filePath);
    
    if (await file.exists()) {
      _memoryCache[song.id] = filePath;
      _cacheOrder.remove(song.id);
      _cacheOrder.add(song.id);
      return filePath;
    }
    
    return null;
  }

  static Future<String?> cacheSong(Song song) async {
    if (song.streamUrl == null) return null;
    
    // Check if already cached
    final existing = await getCachedSongPath(song);
    if (existing != null) return existing;
    
    try {
      final cachePath = await _getCachePath();
      final fileName = '${song.id}_cache.mp3';
      final filePath = '$cachePath/$fileName';
      
      // Download to cache with timeout
      await _dio.download(
        song.streamUrl!, 
        filePath,
        options: Options(
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      
      // Add to memory cache
      _memoryCache[song.id] = filePath;
      
      // Update cache order
      _cacheOrder.remove(song.id);
      _cacheOrder.add(song.id);
      
      // Clean old cache if needed (non-blocking)
      _cleanOldCache();
      
      return filePath;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _cleanOldCache() async {
    if (_cacheOrder.length <= maxCacheSize) return;
    
    final cachePath = await _getCachePath();
    final toRemove = _cacheOrder.length - maxCacheSize;
    
    for (int i = 0; i < toRemove; i++) {
      final songId = _cacheOrder[i];
      final fileName = '${songId}_cache.mp3';
      final filePath = '$cachePath/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from memory cache
      _memoryCache.remove(songId);
    }
    
    _cacheOrder = _cacheOrder.sublist(toRemove);
  }

  static Future<void> removeCachedSong(String songId) async {
    try {
      final cachePath = await _getCachePath();
      final fileName = '${songId}_cache.mp3';
      final filePath = '$cachePath/$fileName';
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _cacheOrder.remove(songId);
      _memoryCache.remove(songId);
    } catch (_) {
      // Error removing cached song
    }
  }
  
  static Future<void> clearCache() async {
    final cachePath = await _getCachePath();
    final cacheDir = Directory(cachePath);
    
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
    
    _cacheOrder.clear();
    _memoryCache.clear();
  }
}