import 'package:flutter/services.dart';
import 'music_data_source.dart';

class NewPipeDataSource implements MusicDataSource {
  static const _channel = MethodChannel('com.myapp/newpipe_data_source');

  @override
  Future<List<Song>> search(String query) async {
    try {
      final List<dynamic> results = await _channel.invokeMethod('search', {'query': query});
      
      return results.map((item) {
        final map = Map<String, dynamic>.from(item);
        return Song(
          id: map['id'] ?? '',
          title: map['title'] ?? '',
          artist: map['artist'] ?? '',
          album: map['album'] ?? '',
          thumbnailUrl: map['thumbnailUrl'] ?? '',
          metadata: {},
        );
      }).toList();
    } catch (e) {
      throw Exception('NewPipe search failed: $e');
    }
  }

  @override
  Future<String> getStreamUrl(String id, Map<String, dynamic> metadata) async {
    try {
      final String url = await _channel.invokeMethod('getStreamUrl', {'id': id});
      return url;
    } catch (e) {
      throw Exception('Failed to get stream URL: $e');
    }
  }
  
  Future<Map<String, dynamic>> getChannelVideos(String channelUrl) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('getChannelVideos', {'channelUrl': channelUrl});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      throw Exception('Failed to get channel videos: $e');
    }
  }
}
