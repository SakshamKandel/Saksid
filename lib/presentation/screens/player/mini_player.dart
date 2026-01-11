import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../controllers/enhanced_player_controller.dart';
import '../../../services/audio/enhanced_audio_player_service.dart';
import 'player_screen.dart';

/// Premium Glass Mini Player with smooth animations
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color _accent = Color(0xFFE50914);
  static const Color _glass = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _retryPlayback(
      BuildContext context, EnhancedPlayerController controller) {
    controller.clearError();
    final currentSong = controller.currentSong;
    if (currentSong != null) {
      controller.playSong(currentSong);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        if (!controller.isMiniPlayerVisible || controller.currentSong == null) {
          return const SizedBox.shrink();
        }

        final song = controller.currentSong!;
        final progress = controller.duration.inMilliseconds > 0
            ? controller.position.inMilliseconds /
                controller.duration.inMilliseconds
            : 0.0;

        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: Offset.zero,
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: 1.0,
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const PlayerScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _glass.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated progress bar
                          Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Stack(
                                children: [
                                  Container(
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: MediaQuery.of(context).size.width *
                                        progress *
                                        0.85,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [_accent, Color(0xFFFF4757)],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accent.withOpacity(0.5),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                            child: Row(
                              children: [
                                // Album art with glow
                                Hero(
                                  tag: 'album_art_${song.id}',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accent.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: song.thumbnailUrl,
                                        width: 52,
                                        height: 52,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            Container(
                                          color: Colors.grey[900],
                                          child: const Icon(Icons.music_note,
                                              color: Colors.white38),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          color: Colors.grey[900],
                                          child: const Icon(Icons.music_note,
                                              color: Colors.white38),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Song info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        song.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          if (controller.isPlaying)
                                            AnimatedBuilder(
                                              animation: _pulseAnimation,
                                              builder: (context, child) {
                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      right: 6),
                                                  child: Icon(
                                                    Icons.graphic_eq,
                                                    color: _accent.withOpacity(
                                                        _pulseAnimation.value),
                                                    size: 14,
                                                  ),
                                                );
                                              },
                                            ),
                                          Expanded(
                                            child: Text(
                                              song.artist,
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Control buttons
                                _buildControlButton(
                                  Icons.skip_previous_rounded,
                                  controller.previous,
                                  size: 28,
                                ),
                                const SizedBox(width: 4),
                                _buildPlayPauseButton(controller),
                                const SizedBox(width: 4),
                                _buildControlButton(
                                  Icons.skip_next_rounded,
                                  controller.next,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed,
      {double size = 24}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white70, size: size),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(EnhancedPlayerController controller) {
    final isError = controller.playbackStatus == PlaybackStatus.error;
    final isLoading = controller.isLoading;
    final isPlaying = controller.isPlaying;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : isError
                ? () => _retryPlayback(context, controller)
                : controller.togglePlayPause,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: isError
                ? null
                : const LinearGradient(colors: [_accent, Color(0xFFB91C1C)]),
            color: isError ? Colors.transparent : null,
            shape: BoxShape.circle,
            border: isError ? Border.all(color: _accent, width: 2) : null,
            boxShadow: isError
                ? null
                : [
                    BoxShadow(
                      color: _accent.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  isError
                      ? Icons.refresh_rounded
                      : isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
        ),
      ),
    );
  }
}
