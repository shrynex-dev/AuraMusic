import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';

class SongCard extends ConsumerWidget {
  final Song song;
  final List<Song>? playlist;

  const SongCard({super.key, required this.song, this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerNotifierProvider);
    final isCurrentSong = currentSong?.id == song.id;
    
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          ref.read(playerNotifierProvider.notifier).playSong(song, playlist: playlist);
        },
        child: Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: song.albumArt != null
                        ? CachedNetworkImage(
                            imageUrl: song.albumArt!,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                            maxWidthDiskCache: 300,
                            maxHeightDiskCache: 300,
                            fadeInDuration: const Duration(milliseconds: 200),
                          )
                        : Container(
                            width: 150,
                            height: 150,
                            color: Theme.of(context).colorScheme.surface,
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                  ),
                  if (isCurrentSong)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Icon(
                          ref.watch(isPlayingProvider) ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                song.artist,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
