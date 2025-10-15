import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/database_service.dart';
import '../../shared/models/song.dart';
import '../../shared/widgets/song_list_tile.dart';
import '../../shared/providers/player_provider.dart';
import 'playlists_screen.dart';
import 'followed_artists_screen.dart';

final likedSongsProvider = FutureProvider.autoDispose<List<Song>>((ref) {
  ref.watch(currentSongProvider);
  return DatabaseService.getLikedSongs();
});
final recentlyPlayedLibraryProvider = FutureProvider<List<Song>>((ref) => DatabaseService.getRecentlyPlayed());

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Library', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _LibraryCard(
            icon: Icons.favorite,
            title: 'Liked Music',
            subtitle: 'Your favorite songs',
            color: Colors.red,
            onTap: () => context.push('/playlist/liked'),
          ),
          const SizedBox(height: 12),
          _LibraryCard(
            icon: Icons.playlist_play,
            title: 'Playlists',
            subtitle: 'Your custom playlists',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PlaylistsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _LibraryCard(
            icon: Icons.download,
            title: 'Downloads',
            subtitle: 'Offline music',
            color: Colors.green,
            onTap: () => context.push('/downloads'),
          ),
          const SizedBox(height: 12),
          _LibraryCard(
            icon: Icons.person,
            title: 'Followed Artists',
            subtitle: 'Artists you follow',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FollowedArtistsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _LibraryCard(
            icon: Icons.history,
            title: 'Recently Played',
            subtitle: 'Your listening history',
            color: Colors.orange,
            onTap: () => _showRecentlyPlayed(context, ref),
          ),
        ],
      ),
    );
  }

  void _showRecentlyPlayed(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Recently Played',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ref.watch(recentlyPlayedLibraryProvider).when(
                  data: (songs) => ListView.builder(
                    controller: scrollController,
                    itemCount: songs.length,
                    addAutomaticKeepAlives: false,
                    itemBuilder: (context, index) => SongListTile(song: songs[index], playlist: songs),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _LibraryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
