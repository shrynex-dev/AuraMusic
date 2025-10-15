import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/album.dart';
import '../../shared/models/song.dart';
import '../../core/services/api_service.dart';
import '../../shared/widgets/song_list_tile.dart';

final albumTracksProvider = FutureProvider.family<List<Song>, Album>((ref, album) async {
  return await ApiService.getAlbumTracks(album);
});

class AlbumDetailScreen extends ConsumerWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(albumTracksProvider(album));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            floating: false,
            snap: false,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (album.imageUrl != null)
                      Image.network(
                        album.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.album, size: 100, color: Colors.grey),
                        ),
                      )
                    else
                      Container(
                        color: Colors.grey[900],
                        child: const Icon(Icons.album, size: 100, color: Colors.grey),
                      ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            album.artist,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                album.source == 'archive' ? Icons.archive : Icons.music_note,
                                size: 16,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                album.source == 'archive' ? 'Archive.org' : 'YouTube',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          tracksAsync.when(
            data: (tracks) => tracks.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: Text('No tracks found')),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => SongListTile(song: tracks[index], playlist: tracks),
                      childCount: tracks.length,
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}