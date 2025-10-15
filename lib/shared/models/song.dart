import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  late String songId;
  @HiveField(2)
  late String title;
  @HiveField(3)
  late String artist;
  @HiveField(4)
  String? album;
  @HiveField(5)
  String? albumArt;
  @HiveField(6)
  String? streamUrl;
  @HiveField(7)
  int? duration;
  @HiveField(8)
  String source;
  @HiveField(9)
  bool isLiked = false;
  @HiveField(10)
  bool isDownloaded = false;
  @HiveField(11)
  String? localPath;
  @HiveField(12)
  DateTime? lastPlayed;
  @HiveField(13)
  int playCount = 0;
  @HiveField(14)
  String? youtubeId;

  Song({
    String? id,
    required this.songId,
    required this.title,
    required this.artist,
    this.album,
    this.albumArt,
    this.streamUrl,
    this.duration,
    required this.source,
    this.youtubeId,
  }) : id = id ?? songId;
  
  factory Song.fromArchiveJson(Map<String, dynamic> json) {
    return Song(
      songId: json['identifier'] ?? '',
      title: json['title'] ?? 'Unknown',
      artist: json['creator'] ?? 'Unknown Artist',
      album: json['collection']?.first ?? '',
      albumArt: json['identifier'] != null 
          ? 'https://archive.org/services/img/${json['identifier']}'
          : null,
      streamUrl: json['identifier'] != null
          ? 'https://archive.org/download/${json['identifier']}'
          : null,
      source: 'archive',
    );
  }
  

}
