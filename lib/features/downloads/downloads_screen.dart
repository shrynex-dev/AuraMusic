import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/download_service.dart';
import '../../shared/models/song.dart';
import '../../shared/widgets/song_list_tile.dart';
import '../../shared/widgets/mini_player.dart';
import '../../shared/providers/download_provider.dart';

final downloadedSongsProvider = FutureProvider<List<Song>>((ref) async {
  return await DownloadService.getAllDownloadedSongs();
});

final downloadRefreshProvider = StateProvider<int>((ref) => 0);

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(downloadedSongsProvider);
    await ref.read(downloadedSongsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(downloadRefreshProvider);
    final songsAsync = ref.watch(downloadedSongsProvider);
    final downloadStatus = ref.watch(downloadStatusProvider);
    
    ref.listen(downloadStatusProvider, (previous, next) {
      if (previous != null && previous.isNotEmpty && next.isEmpty) {
        ref.invalidate(downloadedSongsProvider);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          if (downloadStatus.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Downloading',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...downloadStatus.values.map((status) =>
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    status.title,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${(status.progress * 100).toInt()}%',
                                  style: TextStyle(color: Colors.grey[400]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: status.progress,
                              backgroundColor: Colors.grey[800],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: songsAsync.when(
        data: (songs) {
          if (songs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 64,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No downloaded songs',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) => SongListTile(song: songs[index], playlist: songs),
            ),
          );
        },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
