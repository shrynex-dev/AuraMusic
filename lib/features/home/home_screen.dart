import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/api_service.dart';
import '../../core/services/database_service.dart';
import '../../shared/models/song.dart';
import '../../shared/widgets/song_card.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/models/album.dart';
import '../settings/settings_screen.dart';
import 'see_all_screen.dart';

final recentlyPlayedProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  ref.keepAlive();
  return await DatabaseService.getRecentlyPlayed();
});

final trendingSongsProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  ref.keepAlive();
  return await ApiService.getTrendingSongs();
});

final trendingAlbumsProvider = FutureProvider.autoDispose<List<Album>>((ref) async {
  ref.keepAlive();
  return await ApiService.searchAlbums('popular');
});

final youtubeTrendingProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  ref.keepAlive();
  return await ApiService.searchSongs('music');
});

final youtubeTop50Provider = FutureProvider.autoDispose<List<Song>>((ref) async {
  ref.keepAlive();
  return await ApiService.searchSongs('popular songs');
});

final youtubeNewHotProvider = FutureProvider.autoDispose<List<Song>>((ref) async {
  ref.keepAlive();
  return await ApiService.searchSongs('latest hits');
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _getGreetingColor(BuildContext context) {
    final hour = DateTime.now().hour;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      return Colors.black.withValues(alpha: 0.3);
    }
    
    if (hour < 12) return Colors.orange.withValues(alpha: 0.2);
    if (hour < 17) return Colors.blue.withValues(alpha: 0.2);
    return Colors.indigo.withValues(alpha: 0.2);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final recentlyPlayed = ref.watch(recentlyPlayedProvider);
    final youtubeTrending = ref.watch(youtubeTrendingProvider);
    final youtubeTop50 = ref.watch(youtubeTop50Provider);
    final youtubeNewHot = ref.watch(youtubeNewHotProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: _getGreetingColor(context),
            title: Text(
              _getGreeting(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                recentlyPlayed.when(
                  data: (songs) => songs.isEmpty
                      ? const SizedBox.shrink()
                      : _buildSection(
                          context,
                          'Recently Played',
                          songs,
                        ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (recentlyPlayed.value?.isNotEmpty ?? false) const SizedBox(height: 24),
                youtubeTrending.when(
                  data: (songs) => _buildSection(
                    context,
                    '🔥 Trending on YouTube',
                    songs,
                  ),
                  loading: () => _buildSkeletonSection(context, '🔥 Trending on YouTube'),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                youtubeTop50.when(
                  data: (songs) => _buildSection(
                    context,
                    '🎵 Top 50',
                    songs,
                  ),
                  loading: () => _buildSkeletonSection(context, '🎵 Top 50'),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                youtubeNewHot.when(
                  data: (songs) => _buildSection(
                    context,
                    '🆕 New & Hot',
                    songs,
                  ),
                  loading: () => _buildSkeletonSection(context, '🆕 New & Hot'),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Song> songs) {
    final displaySongs = songs.take(10).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (songs.length > 10)
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SeeAllScreen(title: title, songs: songs),
                    ),
                  ),
                  child: Text(
                    'See all',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displaySongs.length,
            cacheExtent: 500,
            addAutomaticKeepAlives: true,
            addRepaintBoundaries: true,
            itemBuilder: (context, index) {
              return SongCard(song: displaySongs[index], playlist: songs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonSection(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) => const SongCardSkeleton(),
          ),
        ),
      ],
    );
  }
}
