import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/models/song_model.dart';
import '../../controllers/enhanced_player_controller.dart';
import '../playlist/playlist_screen.dart';
import '../playlist/create_playlist_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text(
          'Your Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFDC143C),
          labelColor: const Color(0xFFDC143C),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Favorites'),
            Tab(text: 'Recent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PlaylistsTab(),
          FavoritesTab(),
          RecentlyPlayedTab(),
        ],
      ),
    );
  }
}

class PlaylistsTab extends StatelessWidget {
  const PlaylistsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        final playlists = controller.getAllPlaylists();

        return Column(
          children: [
            // Create Playlist Button
            ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, color: Color(0xFFDC143C), size: 32),
              ),
              title: const Text(
                'Create Playlist',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Build your own playlist',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onTap: () => _showCreatePlaylistDialog(context, controller),
            ),
            const Divider(color: Colors.grey, height: 1),
            // Playlists List
            Expanded(
              child: playlists.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.playlist_play,
                      title: 'No playlists yet',
                      subtitle: 'Create your first playlist',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return _buildPlaylistTile(context, playlist, controller);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistTile(BuildContext context, PlaylistModel playlist, EnhancedPlayerController controller) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: playlist.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: playlist.thumbnailUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: const Color(0xFF2A2A2A),
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFF2A2A2A),
                  child: const Icon(Icons.music_note, color: Colors.white54),
                ),
              )
            : Container(
                width: 56,
                height: 56,
                color: const Color(0xFF2A2A2A),
                child: const Icon(Icons.playlist_play, color: Colors.white54),
              ),
      ),
      title: Text(
        playlist.name,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${playlist.songs.length} songs',
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white54),
        color: const Color(0xFF2A2A2A),
        onSelected: (value) {
          if (value == 'play') {
            if (playlist.songs.isNotEmpty) {
              controller.playPlaylist(playlist.songs);
            }
          } else if (value == 'delete') {
            _showDeleteConfirmation(context, playlist, controller);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'play',
            child: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.white),
                SizedBox(width: 8),
                Text('Play', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaylistScreen(playlist: playlist),
          ),
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, EnhancedPlayerController controller) {
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
                await controller.createPlaylist(nameController.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playlist "${nameController.text}" created'),
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

  void _showDeleteConfirmation(BuildContext context, PlaylistModel playlist, EnhancedPlayerController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await controller.deletePlaylist(playlist.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Playlist deleted'),
                  backgroundColor: Color(0xFFDC143C),
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class FavoritesTab extends StatelessWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        final favorites = controller.getFavorites();

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No favorite songs',
                  style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon to add favorites',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Play All Button
            if (favorites.isNotEmpty)
              ListTile(
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFDC143C), const Color(0xFF8B0000)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
                title: const Text(
                  'Play All',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${favorites.length} songs',
                  style: TextStyle(color: Colors.grey[400]),
                ),
                onTap: () => controller.playPlaylist(favorites),
              ),
            const Divider(color: Colors.grey, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final song = favorites[index];
                  return _buildSongTile(context, song, favorites, index, controller);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongTile(BuildContext context, SongModel song, List<SongModel> songs, int index, EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;

    return ListTile(
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
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: Color(0xFFDC143C)),
        onPressed: () async {
          await controller.toggleFavorite(song);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
      onTap: () => controller.playPlaylist(songs, startIndex: index),
    );
  }
}

class RecentlyPlayedTab extends StatelessWidget {
  const RecentlyPlayedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        final recentSongs = controller.getRecentlyPlayed();

        if (recentSongs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No recently played',
                  style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start playing music to see history',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Clear History Button
            ListTile(
              leading: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.clear_all, color: Colors.white54, size: 32),
              ),
              title: const Text(
                'Clear History',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${recentSongs.length} songs',
                style: TextStyle(color: Colors.grey[400]),
              ),
              onTap: () => _showClearConfirmation(context, controller),
            ),
            const Divider(color: Colors.grey, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: recentSongs.length,
                itemBuilder: (context, index) {
                  final song = recentSongs[index];
                  return _buildSongTile(context, song, recentSongs, index, controller);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongTile(BuildContext context, SongModel song, List<SongModel> songs, int index, EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;

    return ListTile(
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
      trailing: IconButton(
        icon: Icon(
          controller.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
          color: controller.isFavorite(song.id) ? const Color(0xFFDC143C) : Colors.white54,
        ),
        onPressed: () async {
          final isFav = await controller.toggleFavorite(song);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFav ? 'Added to favorites' : 'Removed from favorites'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
      onTap: () => controller.playPlaylist(songs, startIndex: index),
    );
  }

  void _showClearConfirmation(BuildContext context, EnhancedPlayerController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Clear History', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to clear your recently played history?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await controller.clearRecentlyPlayed();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History cleared'),
                  backgroundColor: Color(0xFFDC143C),
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
