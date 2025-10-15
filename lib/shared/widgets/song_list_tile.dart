import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import 'song_options_sheet.dart';

class SongListTile extends ConsumerWidget {
  final Song song;
  final List<Song>? playlist;

  const SongListTile({super.key, required this.song, this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch current song to update like status
    final currentSong = ref.watch(playerNotifierProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isCurrentSong = currentSong?.id == song.id;
    final displaySong = isCurrentSong ? currentSong! : song;
    final showLoading = isLoading && isCurrentSong;
    
    return RepaintBoundary(
      child: ListTile(
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.albumArt != null
                  ? CachedNetworkImage(
                      imageUrl: song.albumArt!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      memCacheWidth: 112,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Theme.of(context).colorScheme.surface,
                      child: const Icon(Icons.music_note),
                    ),
            ),
            if (isCurrentSong)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black.withOpacity(0.4),
                  ),
                  child: Icon(
                    ref.watch(isPlayingProvider) ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      title: Text(
        displaySong.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        displaySong.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[  
            if (displaySong.isLiked)
              Icon(
                Icons.favorite,
                size: 16,
                color: Colors.red,
              ),
            const SizedBox(width: 4),
            Icon(
              displaySong.source == 'archive' ? Icons.archive : Icons.music_note,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.grey[900],
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => SongOptionsSheet(song: displaySong),
              );
            },
            child: Icon(
              Icons.more_vert,
              size: 20,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
        onTap: () => ref.read(playerNotifierProvider.notifier).playSong(displaySong, playlist: playlist),
      ),
    );
  }
}
