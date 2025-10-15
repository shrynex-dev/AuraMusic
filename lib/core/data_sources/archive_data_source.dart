import 'dart:convert';
import 'package:dio/dio.dart';
import 'music_data_source.dart';

class ArchiveDataSource implements MusicDataSource {
  final _dio = Dio();

  @override
  Future<List<Song>> search(String query) async {
    try {
      final response = await _dio.get(
        'https://archive.org/advancedsearch.php',
        queryParameters: {
          'q': '$query AND mediatype:audio',
          'fl': 'identifier,title,creator,collection',
          'rows': 20,
          'output': 'json',
        },
      );

      final data = response.data;
      final docs = data['response']['docs'] as List;

      return docs.map((item) {
        return Song(
          id: item['identifier'] ?? '',
          title: item['title'] ?? 'Unknown',
          artist: item['creator'] ?? 'Unknown Artist',
          album: (item['collection'] as List?)?.first ?? '',
          thumbnailUrl: item['identifier'] != null 
              ? 'https://archive.org/services/img/${item['identifier']}'
              : '',
          metadata: {
            'identifier': item['identifier'],
            'title': item['title'],
            'creator': item['creator'],
          },
        );
      }).toList();
    } catch (e) {
      throw Exception('Archive.org search failed: $e');
    }
  }

  @override
  Future<String> getStreamUrl(String id, Map<String, dynamic> metadata) async {
    try {
      final identifier = metadata['identifier'] ?? id;
      
      final response = await _dio.get(
        'https://archive.org/metadata/$identifier',
      );

      final data = response.data;
      final files = data['files'] as List;

      final audioFile = files.firstWhere(
        (file) => file['format'] == 'VBR MP3' || 
                  file['format'] == 'MP3' ||
                  file['format'] == 'Ogg Vorbis',
        orElse: () => throw Exception('No audio file found'),
      );

      return 'https://archive.org/download/$identifier/${audioFile['name']}';
    } catch (e) {
      throw Exception('Failed to get Archive.org stream: $e');
    }
  }
}