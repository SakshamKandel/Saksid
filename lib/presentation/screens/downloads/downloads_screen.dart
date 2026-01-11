import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../controllers/enhanced_player_controller.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Consumer<EnhancedPlayerController>(
            builder: (context, controller, _) {
              return StreamBuilder(
                stream: controller.downloadService.downloadedSongsStream,
                builder: (context, snapshot) {
                  final downloads = snapshot.data ?? [];
                  if (downloads.isEmpty) return const SizedBox.shrink();

                  return IconButton(
                    icon: const Icon(Icons.play_circle_fill),
                    tooltip: 'Play All',
                    onPressed: () => controller.playPlaylist(downloads),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<EnhancedPlayerController>(
        builder: (context, controller, child) {
          return StreamBuilder(
            stream: controller.downloadService.downloadedSongsStream,
            builder: (context, snapshot) {
              final downloads = snapshot.data ?? [];

              if (downloads.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download_done, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'No downloaded songs yet',
                        style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Download songs to listen offline',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // This will need a callback or navigation to search
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Search for songs to download')),
                          );
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Find Music'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC143C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Stats Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC143C).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.download_done, color: Color(0xFFDC143C)),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${downloads.length} songs downloaded',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Available offline',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                            ),
                          ],
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => controller.playPlaylist(downloads),
                          icon: const Icon(Icons.play_arrow, color: Color(0xFFDC143C)),
                          label: const Text('Play All', style: TextStyle(color: Color(0xFFDC143C))),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  // Downloads List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 160),
                      itemCount: downloads.length,
                      itemBuilder: (context, index) {
                        final song = downloads[index];
                        return _buildSongTile(context, song, downloads, index, controller);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSongTile(BuildContext context, SongModel song, List<SongModel> downloads, int index, EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;
    final isFavorite = controller.isFavorite(song.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isCurrentSong ? const Color(0xFFDC143C).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => controller.playPlaylist(downloads, startIndex: index),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: song.thumbnailUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[800],
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.download_done,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          color: isCurrentSong ? const Color(0xFFDC143C) : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? const Color(0xFFDC143C) : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () async {
                    final result = await controller.toggleFavorite(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result ? 'Added to favorites' : 'Removed from favorites'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  onPressed: () => _showSongOptions(context, song, controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSongOptions(BuildContext context, SongModel song, EnhancedPlayerController controller) {
    final isFavorite = controller.isFavorite(song.id);
    final playlists = controller.getAllPlaylists();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(song.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(song.artist, style: TextStyle(color: Colors.grey[400])),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.white),
            title: const Text('Play', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              controller.playSong(song);
            },
          ),
          ListTile(
            leading: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFDC143C) : Colors.white,
            ),
            title: Text(
              isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              final result = await controller.toggleFavorite(song);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result ? 'Added to favorites' : 'Removed from favorites'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.white),
            title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistSheet(context, song, controller, playlists);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share, color: Colors.white),
            title: const Text('Share', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                'Check out "${song.title}" by ${song.artist}!',
                subject: song.title,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Download', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, controller, song);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddToPlaylistSheet(BuildContext context, SongModel song, EnhancedPlayerController controller, List<PlaylistModel> playlists) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add to Playlist',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.add, color: Color(0xFFDC143C)),
            ),
            title: const Text('Create New Playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showCreatePlaylistDialog(context, song, controller);
            },
          ),
          const Divider(color: Colors.grey),
          if (playlists.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No playlists yet',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  final isInPlaylist = playlist.songs.any((s) => s.id == song.id);

                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: playlist.thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: playlist.thumbnailUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFF2A2A2A),
                              child: const Icon(Icons.playlist_play, color: Colors.white54),
                            ),
                    ),
                    title: Text(playlist.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${playlist.songs.length} songs',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: isInPlaylist
                        ? const Icon(Icons.check_circle, color: Color(0xFFDC143C))
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      if (isInPlaylist) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Song already in this playlist')),
                        );
                      } else {
                        await controller.addSongToPlaylist(playlist.id, song);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added to "${playlist.name}"')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, SongModel song, EnhancedPlayerController controller) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Create Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: Colors.grey[400]),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFDC143C)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final playlist = await controller.createPlaylist(
                  nameController.text.trim(),
                  thumbnailUrl: song.thumbnailUrl,
                );
                await controller.addSongToPlaylist(playlist.id, song);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created "${nameController.text}" and added song'),
                    backgroundColor: const Color(0xFFDC143C),
                  ),
                );
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFFDC143C))),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, EnhancedPlayerController controller, SongModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Download', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${song.title}"? This will remove the downloaded file.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              controller.downloadService.deleteDownload(song.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
