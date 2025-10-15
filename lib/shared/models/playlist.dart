import 'package:hive/hive.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist {
  @HiveField(0)
  String id;
  @HiveField(1)
  late String playlistId;
  @HiveField(2)
  late String name;
  @HiveField(3)
  String? description;
  @HiveField(4)
  String? coverArt;
  @HiveField(5)
  List<String> songIds = [];
  @HiveField(6)
  DateTime createdAt = DateTime.now();
  @HiveField(7)
  DateTime updatedAt = DateTime.now();

  Playlist({
    String? id,
    required this.playlistId,
    required this.name,
    this.description,
    this.coverArt,
  }) : id = id ?? playlistId;
}
