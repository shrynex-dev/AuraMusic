class Album {
  final String id;
  final String title;
  final String artist;
  final String? imageUrl;
  final String source;
  final int? year;
  final String? identifier; // For Archive.org

  Album({
    required this.id,
    required this.title,
    required this.artist,
    this.imageUrl,
    required this.source,
    this.year,
    this.identifier,
  });



  factory Album.fromArchiveJson(Map<String, dynamic> json) {
    final creator = json['creator'];
    return Album(
      id: json['identifier'] ?? '',
      title: json['title'] ?? 'Unknown Album',
      artist: creator is List ? creator.join(', ') : creator?.toString() ?? 'Unknown Artist',
      imageUrl: 'https://archive.org/services/img/${json['identifier']}',
      source: 'archive',
      identifier: json['identifier'],
    );
  }
}