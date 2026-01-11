import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/models/song_model.dart';
import '../../controllers/enhanced_player_controller.dart';

class PlaylistScreen extends StatefulWidget {
  final PlaylistModel playlist;

  const PlaylistScreen({super.key, required this.playlist});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late PlaylistModel _playlist;

  @override
  void initState() {
    super.initState();
    _playlist = widget.playlist;
  }

  void _refreshPlaylist(EnhancedPlayerController controller) {
    final updated = controller.getPlaylist(_playlist.id);
    if (updated != null) {
      setState(() => _playlist = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        // Refresh playlist data
        final updatedPlaylist = controller.getPlaylist(_playlist.id);
        if (updatedPlaylist != null && updatedPlaylist != _playlist) {
          _playlist = updatedPlaylist;
        }

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          body: CustomScrollView(
            slivers: [
              // App Bar with Playlist Image
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: const Color(0xFF000000),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFDC143C).withOpacity(0.6),
                          const Color(0xFF000000),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        // Playlist Cover
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _playlist.thumbnailUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _playlist.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: const Color(0xFF2A2A2A),
                                      child: const Icon(Icons.playlist_play, size: 60, color: Colors.white54),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: const Color(0xFF2A2A2A),
                                      child: const Icon(Icons.playlist_play, size: 60, color: Colors.white54),
                                    ),
                                  )
                                : Container(
                                    color: const Color(0xFF2A2A2A),
                                    child: const Icon(Icons.playlist_play, size: 60, color: Colors.white54),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Playlist Name
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _playlist.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_playlist.songs.length} songs',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Play Controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Shuffle Play Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _playlist.songs.isEmpty
                              ? null
                              : () {
                                  controller.toggleShuffle();
                                  controller.playPlaylist(_playlist.songs);
                                },
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Shuffle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2A2A2A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Play Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _playlist.songs.isEmpty
                              ? null
                              : () => controller.playPlaylist(_playlist.songs),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC143C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Songs List
              if (_playlist.songs.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.music_note, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'No songs in this playlist',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add songs from search or home',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final song = _playlist.songs[index];
                      return _buildSongTile(context, song, index, controller);
                    },
                    childCount: _playlist.songs.length,
                  ),
                ),
              // Bottom Padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSongTile(BuildContext context, SongModel song, int index, EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;

    return Dismissible(
      key: Key(song.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text('Remove Song', style: TextStyle(color: Colors.white)),
            content: Text(
              'Remove "${song.title}" from this playlist?',
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        await controller.removeSongFromPlaylist(_playlist.id, song.id);
        _refreshPlaylist(controller);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${song.title}"'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: const Color(0xFFDC143C),
              onPressed: () async {
                await controller.addSongToPlaylist(_playlist.id, song);
                _refreshPlaylist(controller);
              },
            ),
          ),
        );
      },
      child: ListTile(
        leading: ClipRRect(
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
        title: Text(
          song.title,
          style: TextStyle(
            color: isCurrentSong ? const Color(0xFFDC143C) : Colors.white,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: TextStyle(color: Colors.grey[400]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(song.duration),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: const Color(0xFF2A2A2A),
              onSelected: (value) async {
                if (value == 'remove') {
                  await controller.removeSongFromPlaylist(_playlist.id, song.id);
                  _refreshPlaylist(controller);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed "${song.title}"')),
                  );
                } else if (value == 'favorite') {
                  final isFav = await controller.toggleFavorite(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isFav ? 'Added to favorites' : 'Removed from favorites'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } else if (value == 'download') {
                  controller.downloadSong(song);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Downloading ${song.title}...')),
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(
                        controller.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
                        color: controller.isFavorite(song.id) ? const Color(0xFFDC143C) : Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        controller.isFavorite(song.id) ? 'Remove from Favorites' : 'Add to Favorites',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Download', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.remove_circle_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Remove from Playlist', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => controller.playPlaylist(_playlist.songs, startIndex: index),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
