import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../../core/services/playlist_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/download_service.dart';
import '../providers/player_provider.dart';
import '../providers/download_provider.dart';

final playlistsProvider = StateNotifierProvider<PlaylistsNotifier, List<Playlist>>((ref) {
  return PlaylistsNotifier();
});

class PlaylistsNotifier extends StateNotifier<List<Playlist>> {
  PlaylistsNotifier() : super([]) {
    _loadPlaylists();
  }

  void _loadPlaylists() {
    try {
      state = PlaylistService.getAllPlaylists();
    } catch (e) {
      // Error loading playlists
      state = [];
    }
  }

  Future<void> createPlaylist(String name) async {
    try {
      await PlaylistService.createPlaylist(name);
      _loadPlaylists();
    } catch (e) {
      // Error creating playlist
    }
  }

  Future<void> addToPlaylist(String playlistId, Song song) async {
    try {
      await PlaylistService.addSongToPlaylist(playlistId, song);
      _loadPlaylists();
    } catch (e) {
      // Error adding to playlist
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await PlaylistService.deletePlaylist(playlistId);
      _loadPlaylists();
    } catch (e) {
      // Error deleting playlist
    }
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    try {
      await PlaylistService.renamePlaylist(playlistId, newName);
      _loadPlaylists();
    } catch (e) {
      // Error renaming playlist
    }
  }
}

class SongOptionsSheet extends ConsumerWidget {
  final Song song;

  const SongOptionsSheet({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: song.albumArt != null
                      ? Image.network(
                          song.albumArt!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.grey),
                          ),
                        )
                      : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Consumer(
            builder: (context, ref, child) {
              return ListTile(
                leading: Icon(song.isLiked ? Icons.favorite : Icons.favorite_border),
                title: Text(song.isLiked ? 'Remove from Liked' : 'Add to Liked'),
                onTap: () async {
                  song.isLiked = !song.isLiked;
                  await DatabaseService.saveSong(song);
                  
                  final currentSong = ref.read(currentSongProvider);
                  if (currentSong?.id == song.id) {
                    ref.read(currentSongProvider.notifier).state = Song(
                      id: song.id,
                      songId: song.songId,
                      title: song.title,
                      artist: song.artist,
                      album: song.album,
                      albumArt: song.albumArt,
                      streamUrl: song.streamUrl,
                      duration: song.duration,
                      source: song.source,
                    )
                      ..isLiked = song.isLiked
                      ..isDownloaded = song.isDownloaded
                      ..localPath = song.localPath
                      ..lastPlayed = song.lastPlayed
                      ..playCount = song.playCount;
                  }
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(song.isLiked ? 'Added to liked songs' : 'Removed from liked songs'),
                      ),
                    );
                  }
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add to Playlist'),
            onTap: () => _showPlaylistSelector(context, ref),
          ),
          Consumer(
            builder: (context, ref, child) {
              return ListTile(
                leading: Icon(song.isDownloaded ? Icons.download_done : Icons.download),
                title: Text(song.isDownloaded ? 'Delete Download' : 'Download'),
                onTap: () async {
                  Navigator.pop(context);
                  if (song.isDownloaded) {
                    final success = await DownloadService.deleteSong(song);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? 'Download deleted' : 'Failed to delete')),
                      );
                    }
                  } else {
                    await _handleDownload(context, ref);
                  }
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () async {
              Navigator.pop(context);
              String shareText = '🎵 ${song.title} - ${song.artist}\n\nListen on AuraMusic!';
              
              if (song.youtubeId != null || song.source == 'youtube') {
                final videoId = song.youtubeId ?? song.songId;
                shareText += '\n\nhttps://youtube.com/watch?v=$videoId';
              } else if (song.streamUrl != null) {
                shareText += '\n\n${song.streamUrl}';
              }
              
              try {
                await Share.share(shareText);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to share')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showPlaylistSelector(BuildContext context, WidgetRef ref) {
    final playlists = ref.read(playlistsProvider);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add to Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Playlist'),
              onTap: () => _showCreatePlaylistDialog(context, ref),
            ),
            const Divider(),
            ...playlists.map((playlist) => ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(playlist.name),
              subtitle: Text('${playlist.songIds.length} songs'),
              onTap: () async {
                await ref.read(playlistsProvider.notifier).addToPlaylist(playlist.id, song);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added to ${playlist.name}')),
                  );
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref.read(playlistsProvider.notifier).createPlaylist(controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Created playlist "${controller.text}"')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref) async {
    final downloadNotifier = ref.read(downloadStatusProvider.notifier);
    final location = await DownloadService.getDownloadLocation();
    
    if (location == DownloadLocation.external) {
      final hasPermission = await DownloadService.requestStoragePermission();
      if (!hasPermission && context.mounted) {
        _showPermissionDialog(context, downloadNotifier);
        return;
      }
    }
    
    await _startDownloadWithNotifier(context, downloadNotifier);
  }

  void _showPermissionDialog(BuildContext context, downloadNotifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text('Storage permission is needed to download songs to external storage. You can change download location in settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings');
            },
            child: const Text('Settings'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DownloadService.setDownloadLocation(DownloadLocation.internal);
              if (context.mounted) {
                await _startDownloadWithNotifier(context, downloadNotifier);
              }
            },
            child: const Text('Use Internal Storage'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownloadWithNotifier(BuildContext context, downloadNotifier) async {
    if (!context.mounted) return;
    
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Downloading...'),
        action: SnackBarAction(
          label: 'Details',
          onPressed: () {
            router.push('/downloads');
          },
        ),
      ),
    );
    
    downloadNotifier.startDownload(song.id, song.title);
    
    final success = await DownloadService.downloadSong(
      song,
      onProgress: (progress) {
        downloadNotifier.updateProgress(song.id, progress);
      },
    );
    
    if (success) {
      downloadNotifier.completeDownload(song.id);
    } else {
      downloadNotifier.failDownload(song.id, 'Download failed');
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Downloaded successfully' : 'Download failed')),
      );
    }
  }
}