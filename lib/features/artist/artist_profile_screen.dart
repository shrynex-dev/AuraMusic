import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../shared/models/song.dart';
import '../../shared/widgets/song_list_tile.dart';
import '../../core/data_sources/newpipe_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

final artistSongsProvider = FutureProvider.family<List<Song>, String>((ref, artistName) async {
  return await ApiService.searchSongs(artistName);
});

final artistChannelProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, artistName) async {
  try {
    final songs = await ApiService.searchSongs(artistName);
    if (songs.isEmpty) return null;
    
    final firstSong = songs.first;
    if (firstSong.source != 'youtube') return null;
    
    final newPipe = NewPipeDataSource();
    final channelUrl = 'https://www.youtube.com/channel/${firstSong.artist}';
    return await newPipe.getChannelVideos(channelUrl);
  } catch (e) {
    return null;
  }
});

final artistFollowProvider = StateNotifierProvider.family<ArtistFollowNotifier, bool, String>(
  (ref, artistName) => ArtistFollowNotifier(artistName),
);

class ArtistFollowNotifier extends StateNotifier<bool> {
  final String artistName;
  
  ArtistFollowNotifier(this.artistName) : super(false) {
    _loadFollowStatus();
  }
  
  Future<void> _loadFollowStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('follow_$artistName') ?? false;
  }
  
  Future<void> toggleFollow() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool('follow_$artistName', state);
  }
}

class ArtistProfileScreen extends ConsumerWidget {
  final String artistName;

  const ArtistProfileScreen({super.key, required this.artistName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(artistSongsProvider(artistName));
    final isFollowing = ref.watch(artistFollowProvider(artistName));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade900,
                          Colors.deepPurple.shade800,
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          artistName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(artistFollowProvider(artistName).notifier).toggleFollow();
                    },
                    icon: Icon(isFollowing ? Icons.check : Icons.add),
                    label: Text(isFollowing ? 'Following' : 'Follow'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey[800] : Colors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Popular Songs',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          songsAsync.when(
            data: (songs) {
              final sortedSongs = List<Song>.from(songs)
                ..sort((a, b) => (b.playCount).compareTo(a.playCount));
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => SongListTile(
                    song: sortedSongs[index],
                    playlist: sortedSongs,
                  ),
                  childCount: sortedSongs.length,
                ),
              );
            },
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
