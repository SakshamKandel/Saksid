import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../../../data/models/playlist_model.dart';
import '../../../data/models/song_model.dart';
import '../../controllers/enhanced_player_controller.dart';

/// SakSid Music - Premium Glass Player Screen
/// Features:
/// - Rotating album art (Vinyl style)
/// - Frosted glass controls
/// - Dynamic animated background
/// - Smooth interactions
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _playPauseController;

  // SakSid Design Tokens
  static const Color _accent = Color(0xFFE50914);
  static const Color _glassBorder = Colors.white10;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _playPauseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _playPauseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        final song = controller.currentSong;

        if (song == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: _accent)),
          );
        }

        // Handle animations based on playback state
        if (controller.isPlaying) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
          _playPauseController.forward();
        } else {
          _rotationController.stop();
          _playPauseController.reverse();
        }

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: _buildGlassAppBar(context, controller),
          body: Stack(
            children: [
              // 1. Dynamic Background Layer
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: Container(
                    key: ValueKey(song.thumbnailUrl),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(
                            song.highResThumbnail ?? song.thumbnailUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.black.withOpacity(0.6),
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Content Layer
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Rotating Vinyl Album Art
                      Hero(
                        tag:
                            'album_art_${song.id}', // Updated tag to match MiniPlayer
                        child: AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * math.pi,
                              child: child,
                            );
                          },
                          child: Container(
                            height: 280,
                            width: 280,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                                BoxShadow(
                                  // Subtle vinyl grove shine
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 0,
                                  spreadRadius: 1,
                                ),
                              ],
                              border: Border.all(color: Colors.black, width: 8),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl:
                                    song.highResThumbnail ?? song.thumbnailUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Song Title & Artist (Glass Container)
                      _buildGlassInfoCard(song, controller),

                      const SizedBox(height: 30),

                      // Progress Bar
                      _buildProgressBar(context, controller),

                      const SizedBox(height: 30),

                      // Player Controls
                      _buildGlassControls(controller),

                      const Spacer(flex: 1),

                      // Bottom Actions
                      _buildBottomActions(context, controller, song),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildGlassAppBar(
      BuildContext context, EnhancedPlayerController controller) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white, size: 32),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'NOW PLAYING',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 10,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'SakSid Music',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
          onPressed: () => _showMoreOptions(context, controller),
        ),
      ],
    );
  }

  Widget _buildGlassInfoCard(
      SongModel song, EnhancedPlayerController controller) {
    final isFavorite = controller.isFavorite(song.id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _glassBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(isFavorite),
                    color: isFavorite ? _accent : Colors.white,
                    size: 28,
                  ),
                ),
                onPressed: () => controller.toggleFavorite(song),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      BuildContext context, EnhancedPlayerController controller) {
    final duration = controller.duration.inMilliseconds.toDouble();
    final position = controller.position.inMilliseconds.toDouble();

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: _accent,
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: Colors.white,
            overlayColor: _accent.withOpacity(0.2),
          ),
          child: Slider(
            value: position.clamp(0.0, duration),
            min: 0,
            max: duration > 0 ? duration : 1.0,
            onChanged: (value) {
              controller.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(controller.position),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              Text(
                _formatDuration(controller.duration),
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlassControls(EnhancedPlayerController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.shuffle_rounded,
            color: controller.isShuffle ? _accent : Colors.white54,
            size: 24,
          ),
          onPressed: controller.toggleShuffle,
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded,
              color: Colors.white, size: 36),
          onPressed: controller.previous,
        ),

        // Play/Pause Button with Glow
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_accent, Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: IconButton(
            icon: AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _playPauseController,
              color: Colors.white,
              size: 40,
            ),
            onPressed: controller.isLoading ? null : controller.togglePlayPause,
          ),
        ),

        IconButton(
          icon: const Icon(Icons.skip_next_rounded,
              color: Colors.white, size: 36),
          onPressed: controller.next,
        ),
        IconButton(
          icon: Icon(
            controller.loopMode == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            color:
                controller.loopMode != LoopMode.off ? _accent : Colors.white54,
            size: 24,
          ),
          onPressed: controller.toggleLoopMode,
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context,
      EnhancedPlayerController controller, SongModel song) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGlassActionButton(
          icon: Icons.share_rounded,
          onTap: () =>
              Share.share('Check out "${song.title}" on SakSid Music!'),
        ),
        _buildGlassActionButton(
          icon: Icons.playlist_add_rounded,
          onTap: () => _showAddToPlaylistSheet(context, controller),
        ),
        _buildGlassActionButton(
          icon: Icons.download_rounded,
          onTap: () {
            controller.downloadSong(song);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Downloading...'), backgroundColor: _accent),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGlassActionButton(
      {required IconData icon, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  // --- Helper Methods (Copied from previous implementation with tweaks) ---

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showMoreOptions(
      BuildContext context, EnhancedPlayerController controller) {
    // Keep existing logic but update styling if needed in future
    // For now, standard bottom sheet is fine or we can customize it
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            // ... Add simplified options matching new style
            ListTile(
              leading:
                  const Icon(Icons.info_outline_rounded, color: Colors.white),
              title: const Text('View Album',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistSheet(
      BuildContext context, EnhancedPlayerController controller) {
    // Simplified placeholder for playlist logic to keep file focused on UI
    final playlists = controller.getAllPlaylists();
    final song = controller.currentSong;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add to Playlist',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (song != null)
              ListTile(
                leading: const Icon(Icons.add_box_rounded, color: _accent),
                title: const Text('New Playlist',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistDialog(context, controller, song);
                },
              ),
            // List existing playlists...
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context,
      EnhancedPlayerController controller, SongModel song) {
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
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: _accent)),
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
                final playlist = await controller.createPlaylist(
                    nameController.text,
                    thumbnailUrl: song.thumbnailUrl);
                await controller.addSongToPlaylist(playlist.id, song);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }
}
