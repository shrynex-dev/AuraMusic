import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../shared/models/song.dart';
import '../../shared/models/album.dart';
import '../data_sources/newpipe_data_source.dart';

class ApiService {
  static final Dio _dio = Dio();
  static const _supportedExts = ['mp3', 'm4a', 'aac'];
  static final _newPipeSource = NewPipeDataSource();

  static Future<List<Song>> searchSongs(String query) async {
    return await _searchYouTube(query);
  }

  static Future<List<Map<String, String>>> searchArtists(String query) async {
    try {
      final results = await _newPipeSource.search(query);
      final artistCount = <String, int>{};
      final artistData = <String, Map<String, String>>{};
      
      for (var song in results) {
        artistCount[song.artist] = (artistCount[song.artist] ?? 0) + 1;
        if (!artistData.containsKey(song.artist)) {
          artistData[song.artist] = {
            'name': song.artist,
            'thumbnail': song.thumbnailUrl,
          };
        }
      }
      
      final sortedArtists = artistData.entries.toList()
        ..sort((a, b) => (artistCount[b.key] ?? 0).compareTo(artistCount[a.key] ?? 0));
      
      return sortedArtists.take(5).map((e) => e.value).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Song>> _searchYouTube(String query) async {
    try {
      final results = await _newPipeSource.search(query);
      final songs = results.map((song) => Song(
        songId: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        streamUrl: null,
        albumArt: song.thumbnailUrl,
        source: 'youtube',
        youtubeId: song.id,
      )).toList();
      return songs;
    } catch (e) {
      // YouTube search error
      return [];
    }
  }

  static Future<List<Song>> getTrendingSongs() async {
    // Use popular search terms for trending
    const trendingQueries = ['trending music', 'popular songs', 'top hits'];
    final allSongs = <Song>[];
    
    for (final query in trendingQueries) {
      try {
        final songs = await _searchYouTube(query);
        allSongs.addAll(songs.take(7));
      } catch (_) {}
    }
    
    return allSongs.take(20).toList();
  }

  static Future<List<Song>> searchArchiveAlbums(String term) async {
    if (term.isEmpty) return [];
    
    try {
      final termQuery = '(title:($term) OR creator:($term))';
      final finalQ = '$termQuery AND mediatype:audio';
      
      final response = await _dio.get(
        'https://archive.org/advancedsearch.php',
        queryParameters: {
          'q': finalQ,
          'fl': 'identifier,title,date,creator,downloads',
          'rows': 10,
          'output': 'json',
        },
      );
      
      final docs = (response.data['response']['docs'] as List)
          .where((doc) => !RegExp(r'^[a-z0-9]{30,}\$').hasMatch(doc['identifier']))
          .toList();
      
      final songs = <Song>[];
      for (var doc in docs) {
        final tracks = await _getArchiveTracks(doc['identifier']);
        songs.addAll(tracks);
      }
      
      return songs;
    } catch (e) {
      // Archive search error
      return [];
    }
  }

  static Future<List<Album>> searchAlbums(String query) async {
    if (query.isEmpty) return [];
    return await _searchArchiveAlbums(query);
  }

  static Future<List<Album>> _searchArchiveAlbums(String query) async {
    try {
      final termQuery = '(title:($query) OR creator:($query))';
      final finalQ = '$termQuery AND mediatype:audio';
      
      final response = await _dio.get(
        'https://archive.org/advancedsearch.php',
        queryParameters: {
          'q': finalQ,
          'fl': 'identifier,title,date,creator,downloads',
          'rows': 10,
          'output': 'json',
        },
      );
      
      final docs = (response.data['response']['docs'] as List)
          .where((doc) => !RegExp(r'^[a-z0-9]{30,}\$').hasMatch(doc['identifier']))
          .toList();
      
      return docs.map((doc) => Album.fromArchiveJson(doc)).toList();
    } catch (e) {
      // Archive album search error
      return [];
    }
  }

  static Future<List<Song>> getAlbumTracks(Album album) async {
    return await _getArchiveTracks(album.identifier!);
  }

  static Future<List<Song>> _getArchiveTracks(String identifier) async {
    try {
      final response = await _dio.get('https://archive.org/metadata/$identifier');
      final files = response.data['files'] as List;
      
      final playableFiles = files.where((f) => 
        _supportedExts.any((ext) => (f['name'] as String).endsWith('.$ext'))
      ).toList();
      
      final albumTitle = response.data['metadata']?['title']?.toString() ?? identifier;
      final creator = response.data['metadata']?['creator'];
      final artistName = creator is List ? creator.join(', ') : creator?.toString() ?? 'Unknown';
      
      return playableFiles.map((f) {
        final fileName = f['name'] as String;
        final encodedFileName = Uri.encodeComponent(fileName);
        final streamUrl = 'https://archive.org/download/$identifier/$encodedFileName';
        
        return Song(
          songId: '${identifier}_$fileName',
          title: f['title'] ?? fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
          artist: artistName,
          album: albumTitle,
          streamUrl: streamUrl,
          albumArt: 'https://archive.org/services/img/$identifier',
          source: 'archive',
        );
      }).where((song) => song.streamUrl != null && song.streamUrl!.isNotEmpty).toList();
    } catch (e) {
      // Archive tracks error
      return [];
    }
  }
}
