import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/playlist_model.dart';
import '../../../data/models/song_model.dart';
import '../../controllers/enhanced_player_controller.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        final song = controller.currentSong;

        if (song == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF000000),
            body: Center(child: Text('No song playing', style: TextStyle(color: Colors.white))),
          );
        }

        final isFavorite = controller.isFavorite(song.id);

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Dynamic Blurred Background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(song.highResThumbnail ?? song.thumbnailUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.6),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Container( // Glass frost effect overlay
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Column(
                            children: [
                              const Text(
                                'PLAYING FROM',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Trending Now',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                            onPressed: () => _showMoreOptions(context, controller),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Album Artwork with Shadow
                    Hero(
                      tag: 'current_artwork',
                      child: Container(
                        height: MediaQuery.of(context).size.width - 64,
                        width: MediaQuery.of(context).size.width - 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: CachedNetworkImage(
                            imageUrl: song.highResThumbnail ?? song.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: Colors.grey[900]),
                          ),
                        ),
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Song Info
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  song.artist,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isFavorite ? const Color(0xFFE50914) : Colors.white,
                              size: 28,
                            ),
                            onPressed: () async {
                              final result = await controller.toggleFavorite(song);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result ? 'Added to favorites' : 'Removed from favorites'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF1E1E1E),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                              activeTrackColor: const Color(0xFFE50914),
                              inactiveTrackColor: Colors.white12,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withOpacity(0.1),
                            ),
                            child: Slider(
                              value: controller.position.inMilliseconds.toDouble(),
                              min: 0,
                              max: controller.duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                              onChanged: (value) {
                                controller.seek(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(controller.position),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  _formatDuration(controller.duration),
                                  style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: controller.isShuffle ? const Color(0xFFE50914) : Colors.white54,
                              size: 24,
                            ),
                            onPressed: controller.toggleShuffle,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 42),
                            onPressed: controller.previous,
                          ),
                          Container(
                            height: 72,
                            width: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                controller.isLoading
                                    ? Icons.hourglass_empty_rounded
                                    : controller.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                color: Colors.black, // High contrast
                                size: 36,
                              ),
                              onPressed: controller.isLoading ? null : controller.togglePlayPause,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 42),
                            onPressed: controller.next,
                          ),
                          IconButton(
                            icon: Icon(
                              controller.loopMode == LoopMode.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              color: controller.loopMode != LoopMode.off
                                  ? const Color(0xFFE50914)
                                  : Colors.white54,
                              size: 24,
                            ),
                            onPressed: controller.toggleLoopMode,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Bottom Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.devices_rounded, color: Colors.white54),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.playlist_add_rounded, color: Colors.white54),
                            onPressed: () => _showAddToPlaylistSheet(context, controller),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreOptions(BuildContext context, EnhancedPlayerController controller) {
    final song = controller.currentSong;
    if (song == null) return;

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
            leading: const Icon(Icons.playlist_add, color: Colors.white),
            title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistSheet(context, controller);
            },
          ),
          ListTile(
            leading: Icon(
              controller.isFavorite(song.id) ? Icons.favorite : Icons.favorite_border,
              color: controller.isFavorite(song.id) ? const Color(0xFFDC143C) : Colors.white,
            ),
            title: Text(
              controller.isFavorite(song.id) ? 'Remove from Favorites' : 'Add to Favorites',
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
            leading: const Icon(Icons.download, color: Colors.white),
            title: const Text('Download', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              controller.downloadSong(song);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading ${song.title}...')),
              );
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showAddToPlaylistSheet(BuildContext context, EnhancedPlayerController controller) {
    final song = controller.currentSong;
    if (song == null) return;

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
          const SizedBox(height: 16),
          const Text(
            'Add to Playlist',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Create New Playlist Option
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
              _showCreatePlaylistDialog(context, controller, song);
            },
          ),
          const Divider(color: Colors.grey),
          // Existing Playlists
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

  void _showCreatePlaylistDialog(BuildContext context, EnhancedPlayerController controller, SongModel song) {
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
