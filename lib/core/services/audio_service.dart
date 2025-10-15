import 'dart:io';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../shared/models/song.dart';
import 'cache_service.dart';
import '../data_sources/newpipe_data_source.dart';
import '../data_sources/archive_data_source.dart';

class AudioPlayerService {
  static final AudioPlayer _player = AudioPlayer();
  static List<Song> _currentPlaylist = [];
  static int _currentIndex = 0;
  static int? _audioSessionId;
  static int _playbackId = 0;
  static final _loadingController = StreamController<bool>.broadcast();
  static final _songChangeController = StreamController<Song>.broadcast();
  static ConcatenatingAudioSource? _audioSource;
  static bool _isSkipping = false;
  static final Map<String, AudioSource> _preloadedSources = {};
  static final Map<String, String> _streamUrlCache = {};
  static Timer? _preloadTimer;
  
  static Stream<String> get skipThrottleStream => Stream.empty();

  static AudioPlayer get player => _player;
  static List<Song> get currentPlaylist => _currentPlaylist;
  static int get currentIndex => _currentIndex;
  static int? get audioSessionId => _audioSessionId;
  static Stream<bool> get loadingStream => _loadingController.stream;
  static Stream<Song> get songChangeStream => _songChangeController.stream;

  static Future<void> init() async {
    try {
      _audioSessionId = _player.androidAudioSessionId;
    } catch (_) {}

    _player.sequenceStateStream.listen((sequenceState) {
      if (sequenceState?.currentSource?.tag != null) {
        final mediaItem = sequenceState!.currentSource!.tag as MediaItem;
        final index = sequenceState.currentIndex ?? 0;
        
        if (_currentPlaylist.isNotEmpty && index < _currentPlaylist.length) {
          _currentIndex = index;
          final song = _currentPlaylist[index];
          _songChangeController.add(song);
          _preloadNextSongs();
        }
      }
    });
  }

  static Future<void> playSong(
    Song song, {
    List<Song>? playlist,
    int? index,
  }) async {
    if (song.streamUrl == null &&
        song.localPath == null &&
        song.youtubeId == null) {
      return;
    }

    final playbackId = ++_playbackId;
    _loadingController.add(true);

    try {
      final newPlaylist = playlist ?? [song];
      final newIndex = index ?? 0;

      // Check if song is already loaded in current queue
      if (_audioSource != null && _currentPlaylist.isNotEmpty) {
        final existingIndex = _currentPlaylist.indexWhere((s) => s.id == song.id);
        if (existingIndex != -1 && existingIndex < _audioSource!.length) {
          await _player.seek(Duration.zero, index: existingIndex);
          _loadingController.add(false);
          await _player.play();
          return;
        }
      }

      _currentPlaylist = newPlaylist;
      _currentIndex = newIndex;

      if (playbackId != _playbackId) {
        _loadingController.add(false);
        return;
      }

      // Try to use preloaded source first
      AudioSource? currentSource = _preloadedSources[song.id];
      currentSource ??= await _createAudioSource(song);
      
      if (currentSource == null || playbackId != _playbackId) {
        _loadingController.add(false);
        return;
      }

      _audioSource = ConcatenatingAudioSource(
        children: [currentSource],
        useLazyPreparation: false,
      );

      await _player.setAudioSource(_audioSource!, initialIndex: 0);
      _loadingController.add(false);
      await _player.play();
      
      // Preload next songs immediately
      _preloadNextSongs();
    } catch (e) {
      _loadingController.add(false);
    }
  }

  static void _preloadNextSongs() {
    _preloadTimer?.cancel();
    _preloadTimer = Timer(const Duration(milliseconds: 100), () async {
      final songsToPreload = <Song>[];
      
      // Preload next 2 and previous 1 songs (reduced for memory)
      for (int i = _currentIndex - 1; i <= _currentIndex + 2; i++) {
        if (i >= 0 && i < _currentPlaylist.length && i != _currentIndex) {
          final song = _currentPlaylist[i];
          if (!_preloadedSources.containsKey(song.id)) {
            songsToPreload.add(song);
          }
        }
      }
      
      // Preload in parallel
      final futures = songsToPreload.map((song) async {
        try {
          final source = await _createAudioSource(song)
              .timeout(const Duration(seconds: 8));
          if (source != null) {
            _preloadedSources[song.id] = source;
          }
        } catch (_) {}
      });
      
      await Future.wait(futures);
      
      // Clean up old preloaded sources (keep only 6 for memory efficiency)
      if (_preloadedSources.length > 6) {
        final keys = _preloadedSources.keys.toList();
        for (int i = 0; i < keys.length - 6; i++) {
          _preloadedSources.remove(keys[i]);
        }
      }
    });
  }

  static Future<AudioSource?> _createAudioSource(Song s) async {
    try {
      Uri? audioUri;

      // Check local file first
      if (s.localPath != null) {
        final file = File(s.localPath!);
        if (await file.exists()) {
          audioUri = Uri.file(s.localPath!);
        }
      }
      
      // Check cache
      if (audioUri == null) {
        final cachedPath = await CacheService.getCachedSongPath(s);
        if (cachedPath != null) {
          audioUri = Uri.file(cachedPath);
        }
      }
      
      // Use existing stream URL
      if (audioUri == null && s.streamUrl != null) {
        try {
          audioUri = Uri.parse(s.streamUrl!);
        } catch (_) {}
      }
      
      // Get YouTube stream URL (primary source)
      if (audioUri == null && (s.youtubeId != null || s.source == 'youtube')) {
        try {
          final videoId = s.youtubeId ?? s.songId;
          
          // Check cache first
          String? ytUrl = _streamUrlCache[videoId];
          if (ytUrl == null) {
            ytUrl = await NewPipeDataSource().getStreamUrl(videoId, {});
            _streamUrlCache[videoId] = ytUrl;
            
            // Clean cache if too large (reduced for memory)
            if (_streamUrlCache.length > 30) {
              final keys = _streamUrlCache.keys.toList();
              for (int i = 0; i < 15; i++) {
                _streamUrlCache.remove(keys[i]);
              }
            }
          }
          
          audioUri = Uri.parse(ytUrl);
        } catch (_) {}
      }
      
      // Fallback to Archive.org if YouTube fails
      if (audioUri == null && s.source == 'archive') {
        try {
          final archiveUrl = await ArchiveDataSource().getStreamUrl(s.songId, {
            'identifier': s.songId,
            'title': s.title,
            'creator': s.artist,
          });
          audioUri = Uri.parse(archiveUrl);
        } catch (_) {}
      }

      if (audioUri == null) return null;

      return AudioSource.uri(
        audioUri,
        tag: MediaItem(
          id: s.id,
          album: s.album ?? 'Unknown Album',
          title: s.title,
          artist: s.artist,
          duration: s.duration != null ? Duration(seconds: s.duration!) : null,
          artUri: s.albumArt != null ? Uri.parse(s.albumArt!) : null,
          extras: {'isLiked': s.isLiked},
        ),
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> _ensureNextSongLoaded() async {
    if (_audioSource == null || _currentIndex + 1 >= _currentPlaylist.length) return;
    
    final nextSong = _currentPlaylist[_currentIndex + 1];
    
    // Check if next song is already in the audio source
    if (_currentIndex + 1 < _audioSource!.length) return;
    
    // Try to get preloaded source first
    AudioSource? nextSource = _preloadedSources[nextSong.id];
    
    if (nextSource == null) {
      try {
        nextSource = await _createAudioSource(nextSong)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        return;
      }
    }
    
    if (nextSource != null) {
      try {
        await _audioSource!.add(nextSource);
      } catch (_) {}
    }
  }

  static Future<void> play() => _player.play();
  static Future<void> pause() => _player.pause();
  static Future<void> seek(Duration position) => _player.seek(position);

  static Song? getCurrentSong() {
    if (_currentPlaylist.isEmpty || _currentIndex >= _currentPlaylist.length) {
      return null;
    }
    return _currentPlaylist[_currentIndex];
  }

  static Future<bool> skipToNext() async {
    if (_audioSource == null || _currentPlaylist.isEmpty || _isSkipping) return false;
    if (_currentIndex + 1 >= _currentPlaylist.length) return false;

    _isSkipping = true;
    try {
      final currentSourceIndex = _player.currentIndex ?? 0;
      
      // Ensure next song is loaded
      if (currentSourceIndex + 1 >= _audioSource!.length) {
        await _ensureNextSongLoaded();
      }
      
      // Skip immediately
      await _player.seekToNext();
      _isSkipping = false;
      return true;
    } catch (e) {
      _isSkipping = false;
      return false;
    }
  }

  static Future<bool> skipToPrevious() async {
    if (_audioSource == null || _currentPlaylist.isEmpty || _isSkipping) return false;
    if (_currentIndex <= 0) return false;

    _isSkipping = true;
    try {
      await _player.seekToPrevious();
      _isSkipping = false;
      return true;
    } catch (e) {
      _isSkipping = false;
      return false;
    }
  }
}
