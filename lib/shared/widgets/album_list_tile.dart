import 'package:flutter/material.dart';
import '../models/album.dart';

class AlbumListTile extends StatelessWidget {
  final Album album;
  final VoidCallback? onTap;

  const AlbumListTile({
    super.key,
    required this.album,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: album.imageUrl != null
            ? Image.network(
                album.imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey[800],
                  child: const Icon(Icons.album, color: Colors.grey),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: Colors.grey[800],
                child: const Icon(Icons.album, color: Colors.grey),
              ),
      ),
      title: Text(
        album.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        album.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: Icon(
        album.source == 'archive' ? Icons.archive : Icons.music_note,
        color: Colors.grey[400],
        size: 20,
      ),
      onTap: onTap,
    );
  }
}