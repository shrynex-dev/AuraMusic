import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/song.dart';
import '../../shared/models/album.dart';
import '../../shared/widgets/song_list_tile.dart';
import '../../shared/widgets/album_list_tile.dart';
import '../album/album_detail_screen.dart';

class SeeAllScreen extends ConsumerWidget {
  final String title;
  final List<Song>? songs;
  final List<Album>? albums;

  const SeeAllScreen({
    super.key,
    required this.title,
    this.songs,
    this.albums,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      body: songs != null
          ? ListView.builder(
              itemCount: songs!.length,
              itemBuilder: (context, index) => SongListTile(
                song: songs![index],
                playlist: songs!,
              ),
            )
          : ListView.builder(
              itemCount: albums!.length,
              itemBuilder: (context, index) => AlbumListTile(
                album: albums![index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumDetailScreen(album: albums![index]),
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
