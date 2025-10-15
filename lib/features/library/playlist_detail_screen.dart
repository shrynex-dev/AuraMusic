import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/playlist.dart';
import '../../shared/models/song.dart';
import '../../shared/widgets/song_list_tile.dart';
import '../../shared/providers/database_provider.dart';

final playlistSongsProvider = FutureProvider.family<List<Song>, Playlist>((ref, playlist) async {
  final database = ref.read(databaseServiceProvider);
  final songs = <Song>[];
  for (final songId in playlist.songIds) {
    final song = await database.getSong(songId);
    if (song != null) songs.add(song);
  }
  return songs;
});

class PlaylistDetailScreen extends ConsumerWidget {
  final Playlist playlist;

  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.purple.withOpacity(0.8),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        playlist.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${playlist.songIds.length} songs',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Consumer(
            builder: (context, ref, child) {
              final songsAsync = ref.watch(playlistSongsProvider(playlist));
              return songsAsync.when(
                data: (songs) => songs.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.queue_music, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No songs in this playlist', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => SongListTile(song: songs[index], playlist: songs),
                          childCount: songs.length,
                        ),
                      ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}