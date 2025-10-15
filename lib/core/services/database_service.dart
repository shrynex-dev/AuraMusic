import 'package:hive_flutter/hive_flutter.dart';
import '../../shared/models/song.dart';
import '../../shared/models/playlist.dart';

class DatabaseService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      Hive.registerAdapter(SongAdapter());
      Hive.registerAdapter(PlaylistAdapter());
      _initialized = true;
    } catch (e) {
      // Database init error
      _initialized = true; // Mark as initialized to prevent retry loops
    }
  }

  // Songs
  static Future<void> saveSong(Song song) async {
    final box = await Hive.openBox<Song>('songs');
    await box.put(song.id, song);
  }

  static Future<List<Song>> getLikedSongs() async {
    final box = await Hive.openBox<Song>('songs');
    return box.values.where((song) => song.isLiked).toList();
  }

  static Future<List<Song>> getRecentlyPlayed() async {
    final box = await Hive.openBox<Song>('songs');
    final songs = box.values.where((song) => song.lastPlayed != null).toList();
    songs.sort((a, b) => b.lastPlayed!.compareTo(a.lastPlayed!));
    return songs.take(20).toList();
  }

  static Future<List<Song>> getDownloadedSongs() async {
    final box = await Hive.openBox<Song>('songs');
    return box.values.where((song) => song.isDownloaded).toList();
  }

  static Future<Song?> getSong(String id) async {
    final box = await Hive.openBox<Song>('songs');
    return box.get(id);
  }

  // Playlists
  static Future<void> savePlaylist(Playlist playlist) async {
    final box = await Hive.openBox<Playlist>('playlists');
    await box.put(playlist.id, playlist);
  }

  static Future<List<Playlist>> getAllPlaylists() async {
    final box = await Hive.openBox<Playlist>('playlists');
    return box.values.toList();
  }

  static Future<void> deletePlaylist(String id) async {
    final box = await Hive.openBox<Playlist>('playlists');
    await box.delete(id);
  }
}
