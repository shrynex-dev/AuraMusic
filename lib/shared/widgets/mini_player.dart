import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final currentSong = ref.watch(playerNotifierProvider);
      final isLoading = ref.watch(isLoadingProvider);
      
      return AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: currentSong == null
            ? const SizedBox.shrink()
            : AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: GestureDetector(
          key: ValueKey('${currentSong.id}_$isLoading'),
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -500) {
          HapticFeedback.mediumImpact();
          context.push('/now-playing');
        }
      },
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/now-playing');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: 72,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'album_art_${currentSong.id}',
                  child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: currentSong.albumArt != null
                    ? CachedNetworkImage(
                        imageUrl: currentSong.albumArt!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        fadeOutDuration: const Duration(milliseconds: 100),
                        errorWidget: (context, url, error) => Container(
                          width: 72,
                          height: 72,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          child: const Icon(Icons.music_note),
                        ),
                        placeholder: (context, url) => Container(
                          width: 72,
                          height: 72,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 72,
                        height: 72,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        child: const Icon(Icons.music_note),
                      ),
                  ),
                ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                        color: Colors.black38,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: Text(
                        currentSong.title,
                        key: ValueKey(currentSong.id),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: Text(
                        currentSong.artist,
                        key: ValueKey('${currentSong.id}_artist'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded),
              onPressed: ref.watch(isLoadingProvider) ? null : () {
                HapticFeedback.lightImpact();
                ref.read(playerNotifierProvider.notifier).skipPrevious();
              },
            ),
            IconButton(
              icon: ref.watch(isLoadingProvider)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      ref.watch(isPlayingProvider)
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
              onPressed: ref.watch(isLoadingProvider)
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      ref.read(playerNotifierProvider.notifier).togglePlayPause();
                    },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed: ref.watch(isLoadingProvider) ? null : () {
                HapticFeedback.lightImpact();
                ref.read(playerNotifierProvider.notifier).skipNext();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
        ),
            ),
      );
    } catch (e) {
      // MiniPlayer error
      return const SizedBox.shrink();
    }
  }
}
