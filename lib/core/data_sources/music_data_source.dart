abstract class MusicDataSource {
  Future<List<Song>> search(String query);
  Future<String> getStreamUrl(String id, Map<String, dynamic> metadata);
}

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String thumbnailUrl;
  final Map<String, dynamic> metadata;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.thumbnailUrl,
    required this.metadata,
  });
}
