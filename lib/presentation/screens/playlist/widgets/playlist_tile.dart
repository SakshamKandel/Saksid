import 'package:flutter/material.dart';
import 'package:music_streaming_app/data/models/playlist_model.dart';

class PlaylistTile extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback onTap;

  const PlaylistTile({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.music_note),
      title: Text(playlist.name),
      subtitle: Text('${playlist.songs.length} songs'),
      onTap: onTap,
    );
  }
}
