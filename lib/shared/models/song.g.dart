// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 0;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String?,
      songId: fields[1] as String,
      title: fields[2] as String,
      artist: fields[3] as String,
      album: fields[4] as String?,
      albumArt: fields[5] as String?,
      streamUrl: fields[6] as String?,
      duration: fields[7] as int?,
      source: fields[8] as String,
      youtubeId: fields[14] as String?,
    )
      ..isLiked = fields[9] as bool
      ..isDownloaded = fields[10] as bool
      ..localPath = fields[11] as String?
      ..lastPlayed = fields[12] as DateTime?
      ..playCount = fields[13] as int;
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.songId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.artist)
      ..writeByte(4)
      ..write(obj.album)
      ..writeByte(5)
      ..write(obj.albumArt)
      ..writeByte(6)
      ..write(obj.streamUrl)
      ..writeByte(7)
      ..write(obj.duration)
      ..writeByte(8)
      ..write(obj.source)
      ..writeByte(9)
      ..write(obj.isLiked)
      ..writeByte(10)
      ..write(obj.isDownloaded)
      ..writeByte(11)
      ..write(obj.localPath)
      ..writeByte(12)
      ..write(obj.lastPlayed)
      ..writeByte(13)
      ..write(obj.playCount)
      ..writeByte(14)
      ..write(obj.youtubeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
