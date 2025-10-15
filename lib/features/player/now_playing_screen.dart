import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import '../../shared/providers/player_provider.dart';
import '../../shared/widgets/song_options_sheet.dart';
import '../artist/artist_profile_screen.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(playerNotifierProvider);
    final isLoading = ref.watch(isLoadingProvider);
    
    if (currentSong == null) {
      return Scaffold(
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : const Text('No song playing'),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.grey[900],
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => SongOptionsSheet(song: currentSong),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Blurred background
          if (currentSong.albumArt != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: currentSong.albumArt!,
                fit: BoxFit.cover,
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  // Album Art
                  Hero(
                    tag: 'album_art_${currentSong.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: currentSong.albumArt != null
                          ? CachedNetworkImage(
                              imageUrl: currentSong.albumArt!,
                              width: 320,
                              height: 320,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 320,
                              height: 320,
                              color: Theme.of(context).colorScheme.surface,
                              child: const Icon(Icons.music_note, size: 80),
                            ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Song Info
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      currentSong.title,
                      key: ValueKey('title_${currentSong.id}'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      key: ValueKey('artist_${currentSong.id}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArtistProfileScreen(artistName: currentSong.artist),
                          ),
                        );
                      },
                      child: Text(
                        currentSong.artist,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                              decoration: TextDecoration.underline,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Like and Playlist buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          currentSong.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: currentSong.isLiked ? Colors.red : Colors.white70,
                        ),
                        iconSize: 32,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          ref.read(playerNotifierProvider.notifier).toggleLike();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.playlist_add, color: Colors.white70),
                        iconSize: 32,
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.grey[900],
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => SongOptionsSheet(song: currentSong),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  const _ProgressBar(),
                  const SizedBox(height: 32),
                  // Controls
                  const _PlayerControls(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends ConsumerWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider);
    final duration = ref.watch(durationProvider);

    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: position.inSeconds.toDouble(),
            max: duration.inSeconds.toDouble().clamp(1, double.infinity),
            onChanged: (value) {
              ref.read(playerNotifierProvider.notifier).seekTo(
                    Duration(seconds: value.toInt()),
                  );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _PlayerControls extends ConsumerWidget {
  const _PlayerControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final shuffle = ref.watch(shuffleProvider);
    final repeat = ref.watch(repeatProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            shuffle ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
            color: shuffle ? Theme.of(context).colorScheme.primary : Colors.white70,
          ),
          iconSize: 28,
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(playerNotifierProvider.notifier).toggleShuffle();
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
          iconSize: 40,
          onPressed: ref.watch(isLoadingProvider) ? null : () {
            HapticFeedback.lightImpact();
            ref.read(playerNotifierProvider.notifier).skipPrevious();
          },
        ),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ref.watch(isLoadingProvider)
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.black,
                  ),
                  iconSize: 40,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(playerNotifierProvider.notifier).togglePlayPause();
                  },
                ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
          iconSize: 40,
          onPressed: ref.watch(isLoadingProvider) ? null : () {
            HapticFeedback.lightImpact();
            ref.read(playerNotifierProvider.notifier).skipNext();
          },
        ),
        IconButton(
          icon: Icon(
            repeat == LoopMode.off
                ? Icons.repeat_rounded
                : repeat == LoopMode.one
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_on_rounded,
            color: repeat != LoopMode.off
                ? Theme.of(context).colorScheme.primary
                : Colors.white70,
          ),
          iconSize: 28,
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(playerNotifierProvider.notifier).toggleRepeat();
          },
        ),
      ],
    );
  }
}
