import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/database_service.dart';

final currentSongProvider = StateProvider<Song?>((ref) => null);
final playlistProvider = StateProvider<List<Song>>((ref) => []);
final isPlayingProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final positionProvider = StateProvider<Duration>((ref) => Duration.zero);
final durationProvider = StateProvider<Duration>((ref) => Duration.zero);
final shuffleProvider = StateProvider<bool>((ref) => false);
final repeatProvider = StateProvider<LoopMode>((ref) => LoopMode.off);

class PlayerNotifier extends StateNotifier<Song?> {
  final Ref ref;
  int _playRequestId = 0;
  Timer? _debounceTimer;
  
  PlayerNotifier(this.ref) : super(null) {
    _init();
  }

  void _init() {
    AudioPlayerService.player.playerStateStream.listen((playerState) {
      ref.read(isPlayingProvider.notifier).state = playerState.playing;
      
      if (playerState.processingState == ProcessingState.completed) {
        skipNext();
      }
    });
    
    AudioPlayerService.loadingStream.listen((loading) {
      ref.read(isLoadingProvider.notifier).state = loading;
    });
    
    AudioPlayerService.songChangeStream.listen((song) async {
      state = song;
      ref.read(currentSongProvider.notifier).state = song;
      await _updateSongStats(song);
    });
    
    AudioPlayerService.player.positionStream.listen((position) {
      ref.read(positionProvider.notifier).state = position;
    });
    
    AudioPlayerService.player.durationStream.listen((duration) {
      if (duration != null) {
        ref.read(durationProvider.notifier).state = duration;
      }
    });
  }

  Future<void> _updateSongStats(Song song) async {
    try {
      final savedSong = await DatabaseService.getSong(song.id);
      final songToUpdate = savedSong ?? song;
      songToUpdate.lastPlayed = DateTime.now();
      songToUpdate.playCount++;
      await DatabaseService.saveSong(songToUpdate);
      if (state?.id == song.id) {
        state = songToUpdate;
        ref.read(currentSongProvider.notifier).state = songToUpdate;
      }
    } catch (e) {
      // Ignore stats update errors
    }
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    final requestId = ++_playRequestId;
    
    // Immediate UI feedback
    ref.read(isLoadingProvider.notifier).state = true;
    
    try {
      if (requestId != _playRequestId) return;
      
      // Use song directly for faster response
      final songToPlay = song;
      
      if (requestId != _playRequestId) return;
      
      if (playlist != null) {
        ref.read(playlistProvider.notifier).state = playlist;
        final index = playlist.indexWhere((s) => s.id == songToPlay.id);
        await AudioPlayerService.playSong(songToPlay, playlist: playlist, index: index);
      } else {
        await AudioPlayerService.playSong(songToPlay);
      }
      
      // Update database in background
      _updateSongInBackground(song);
    } catch (e) {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }
  
  void _updateSongInBackground(Song song) {
    Future.microtask(() async {
      try {
        final savedSong = await DatabaseService.getSong(song.id);
        if (savedSong != null && state?.id == song.id) {
          state = savedSong;
          ref.read(currentSongProvider.notifier).state = savedSong;
        }
      } catch (_) {}
    });
  }

  Future<void> togglePlayPause() async {
    try {
      if (AudioPlayerService.player.playing) {
        await AudioPlayerService.pause();
      } else {
        await AudioPlayerService.play();
      }
    } catch (e) {}
  }

  Future<void> seekTo(Duration position) async {
    await AudioPlayerService.seek(position);
  }

  Future<void> skipNext() async {
    // Debounce rapid taps
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () async {
      await AudioPlayerService.skipToNext();
    });
  }

  Future<void> skipPrevious() async {
    // Debounce rapid taps
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () async {
      await AudioPlayerService.skipToPrevious();
    });
  }

  Future<void> toggleShuffle() async {
    final current = ref.read(shuffleProvider);
    ref.read(shuffleProvider.notifier).state = !current;
  }

  Future<void> toggleRepeat() async {
    final current = ref.read(repeatProvider);
    final next = current == LoopMode.off
        ? LoopMode.all
        : current == LoopMode.all
            ? LoopMode.one
            : LoopMode.off;
    ref.read(repeatProvider.notifier).state = next;
  }
  
  Future<void> toggleLike() async {
    if (state != null) {
      final updatedSong = Song(
        id: state!.id,
        songId: state!.songId,
        title: state!.title,
        artist: state!.artist,
        album: state!.album,
        albumArt: state!.albumArt,
        streamUrl: state!.streamUrl,
        duration: state!.duration,
        source: state!.source,
        youtubeId: state!.youtubeId,
      )
        ..isLiked = !state!.isLiked
        ..isDownloaded = state!.isDownloaded
        ..localPath = state!.localPath
        ..lastPlayed = state!.lastPlayed
        ..playCount = state!.playCount;
      
      state = updatedSong;
      await DatabaseService.saveSong(updatedSong);
    }
  }
}

final playerNotifierProvider = StateNotifierProvider<PlayerNotifier, Song?>((ref) {
  return PlayerNotifier(ref);
});
