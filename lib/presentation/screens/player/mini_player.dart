import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../controllers/enhanced_player_controller.dart';
import '../../../services/audio/enhanced_audio_player_service.dart';
import 'player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  void _retryPlayback(BuildContext context, EnhancedPlayerController controller) {
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

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const PlayerScreen()),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: controller.duration.inMilliseconds > 0
                      ? controller.position.inMilliseconds / controller.duration.inMilliseconds
                      : 0,
                  backgroundColor: Colors.grey[700],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC143C)),
                  minHeight: 2,
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.music_note, color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              song.artist,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white),
                        onPressed: controller.previous,
                      ),
                      IconButton(
                        icon: Icon(
                          controller.playbackStatus == PlaybackStatus.error
                              ? Icons.error_outline
                              : controller.isLoading
                                  ? Icons.hourglass_empty
                                  : controller.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                          color: controller.playbackStatus == PlaybackStatus.error
                              ? const Color(0xFFE50914)
                              : Colors.white,
                        ),
                        onPressed: controller.isLoading
                            ? null
                            : controller.playbackStatus == PlaybackStatus.error
                                ? () => _retryPlayback(context, controller)
                                : controller.togglePlayPause,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        onPressed: controller.next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
