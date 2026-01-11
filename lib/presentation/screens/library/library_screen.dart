import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../widgets/animated_list_item.dart';
import '../../widgets/playing_indicator.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/models/song_model.dart';
import '../../controllers/enhanced_player_controller.dart';
import '../playlist/playlist_screen.dart';

/// SakSid Music - Glass Library
/// Features:
/// - Custom Glass AppBar
/// - Animated Tab Switching
/// - Glass List Cards
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const Color _accent = Color(0xFFE50914);

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
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Library',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: _accent,
                      indicatorSize: TabBarIndicatorSize.label,
                      indicatorWeight: 3,
                      labelColor: _accent,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      tabs: const [
                        Tab(text: 'Playlists'),
                        Tab(text: 'Favorites'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color(0xFF0F0F0F)],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: const [
            PlaylistsTab(),
            FavoritesTab(),
            RecentlyPlayedTab(),
          ],
        ),
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

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(
                  top: 120, bottom: 100, left: 16, right: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Create Playlist Button
                  _buildCreatePlaylistButton(context, controller),
                  const SizedBox(height: 16),

                  // Playlist Grid
                  if (playlists.isEmpty)
                    _buildEmptyState()
                  else
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        return AnimatedListItem(
                          index: index,
                          child: _buildPlaylistCard(
                              context, playlists[index], controller),
                        );
                      },
                    ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCreatePlaylistButton(
      BuildContext context, EnhancedPlayerController controller) {
    return InkWell(
      onTap: () => _showCreatePlaylistDialog(context, controller),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFFE50914), size: 28),
            SizedBox(width: 12),
            Text(
              'Create New Playlist',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard(BuildContext context, PlaylistModel playlist,
      EnhancedPlayerController controller) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PlaylistScreen(playlist: playlist)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: playlist.thumbnailUrl != null
                    ? CachedNetworkImage(
                        imageUrl: playlist.thumbnailUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey[900]),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.playlist_play_rounded,
                              size: 48, color: Colors.white24),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.songs.length} Tracks',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(
          children: [
            Icon(Icons.music_note_rounded,
                size: 64, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              'Your collection is empty',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(
      BuildContext context, EnhancedPlayerController controller) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Text('New Playlist', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Name',
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFE50914))),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await controller.createPlaylist(nameController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create',
                style: TextStyle(color: Color(0xFFE50914))),
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
                Icon(Icons.favorite_rounded,
                    size: 80, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 16),
                Text('No favorites yet',
                    style: TextStyle(color: Colors.white.withOpacity(0.5))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 120, bottom: 100),
          physics: const BouncingScrollPhysics(),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            return AnimatedListItem(
              index: index,
              child: _buildSongTile(
                  context, favorites[index], favorites, index, controller),
            );
          },
        );
      },
    );
  }

  Widget _buildSongTile(BuildContext context, SongModel song,
      List<SongModel> songs, int index, EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentSong
            ? const Color(0xFFE50914).withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentSong
            ? Border.all(color: const Color(0xFFE50914).withOpacity(0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            if (isCurrentSong && controller.isPlaying)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: PlayingIndicator(size: 20, color: Color(0xFFE50914)),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            if (isCurrentSong)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: const Color(0xFFE50914).withOpacity(0.5),
                      width: 0.5),
                ),
                child: const Text(
                  'PLAYING',
                  style: TextStyle(
                    color: Color(0xFFE50914),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                song.title,
                style: TextStyle(
                  color: isCurrentSong ? const Color(0xFFE50914) : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(song.artist,
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
            maxLines: 1),
        trailing: IconButton(
          icon: const Icon(Icons.favorite_rounded, color: Color(0xFFE50914)),
          onPressed: () => controller.toggleFavorite(song),
        ),
        onTap: () => controller.playPlaylist(songs, startIndex: index),
      ),
    );
  }
}

class RecentlyPlayedTab extends StatelessWidget {
  const RecentlyPlayedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
        builder: (context, controller, child) {
      final history = controller.getRecentlyPlayed();
      if (history.isEmpty) {
        return Center(
            child: Text('No listening history',
                style: TextStyle(color: Colors.white.withOpacity(0.5))));
      }

      return ListView.builder(
        padding: const EdgeInsets.only(top: 120, bottom: 100),
        physics: const BouncingScrollPhysics(),
        itemCount: history.length,
        itemBuilder: (context, index) {
          return AnimatedListItem(
            index: index,
            child:
                _buildHistoryTile(history[index], history, index, controller),
          );
        },
      );
    });
  }

  Widget _buildHistoryTile(SongModel song, List<SongModel> songs, int index,
      EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: isCurrentSong
          ? BoxDecoration(
              color: const Color(0xFFE50914).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: const Color(0xFFE50914).withOpacity(0.3)),
            )
          : null,
      child: ListTile(
        leading: isCurrentSong
            ? const PlayingIndicator(size: 20, color: Color(0xFFE50914))
            : Icon(Icons.history_rounded, color: Colors.white.withOpacity(0.3)),
        title: Text(song.title,
            style: TextStyle(
                color: isCurrentSong ? const Color(0xFFE50914) : Colors.white,
                fontWeight:
                    isCurrentSong ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(song.artist,
            style: TextStyle(color: Colors.white.withOpacity(0.5))),
        onTap: () => controller.playPlaylist(songs, startIndex: index),
      ),
    );
  }
}
