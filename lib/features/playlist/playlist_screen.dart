import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/database_service.dart';
import '../../shared/models/song.dart';
import '../../shared/widgets/song_list_tile.dart';
import '../../shared/widgets/mini_player.dart';
import '../../shared/providers/player_provider.dart';

final playlistSongsProvider = FutureProvider.autoDispose.family<List<Song>, String>((ref, playlistId) async {
  if (playlistId == 'liked') {
    ref.watch(currentSongProvider);
    return await DatabaseService.getLikedSongs();
  }
  return [];
});

class PlaylistScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(playlistSongsProvider(playlistId));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: songsAsync.when(
        data: (songs) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  playlistId == 'liked' ? 'Liked Music' : 'Playlist',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.favorite, size: 80, color: Colors.white),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: songs.isEmpty ? null : () {},
                      icon: const Icon(Icons.shuffle),
                      label: const Text('Shuffle Play'),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${songs.length} songs',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => SongListTile(song: songs[index], playlist: songs),
                childCount: songs.length,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomSheet: const MiniPlayer(),
    );
  }
}
