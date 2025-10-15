import 'package:hive/hive.dart';
import '../../shared/models/playlist.dart';
import '../../shared/models/song.dart';

class PlaylistService {
  static const String _playlistBoxName = 'playlists';
  static Box<Playlist>? _playlistBox;

  static Future<void> init() async {
    _playlistBox = await Hive.openBox<Playlist>(_playlistBoxName);
  }

  static Box<Playlist> get _box {
    if (_playlistBox == null || !_playlistBox!.isOpen) {
      throw Exception('PlaylistService not initialized');
    }
    return _playlistBox!;
  }

  static List<Playlist> getAllPlaylists() {
    return _box.values.toList();
  }

  static Future<void> createPlaylist(String name) async {
    final playlistId = DateTime.now().millisecondsSinceEpoch.toString();
    final playlist = Playlist(
      playlistId: playlistId,
      name: name,
    );
    await _box.put(playlist.id, playlist);
  }

  static Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlist = _box.get(playlistId);
    if (playlist != null && !playlist.songIds.contains(song.songId)) {
      playlist.songIds.add(song.songId);
      playlist.updatedAt = DateTime.now();
      await _box.put(playlistId, playlist);
    }
  }

  static Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final playlist = _box.get(playlistId);
    if (playlist != null) {
      playlist.songIds.remove(songId);
      playlist.updatedAt = DateTime.now();
      await _box.put(playlistId, playlist);
    }
  }

  static Future<void> deletePlaylist(String playlistId) async {
    await _box.delete(playlistId);
  }

  static Future<void> renamePlaylist(String playlistId, String newName) async {
    final playlist = _box.get(playlistId);
    if (playlist != null) {
      playlist.name = newName;
      playlist.updatedAt = DateTime.now();
      await _box.put(playlistId, playlist);
    }
  }
}