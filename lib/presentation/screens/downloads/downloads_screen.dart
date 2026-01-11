import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../widgets/animated_list_item.dart';
import '../../widgets/playing_indicator.dart';
import '../../../data/models/song_model.dart';
import '../../controllers/enhanced_player_controller.dart';

/// SakSid Music - Glass Downloads Screen
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});
  static const Color _accent = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: Colors.black.withOpacity(0.7),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Downloads',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      _buildPlayAllButton(context),
                    ],
                  ),
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
        child: Consumer<EnhancedPlayerController>(
          builder: (context, controller, child) {
            return StreamBuilder(
              stream: controller.downloadService.downloadedSongsStream,
              builder: (context, snapshot) {
                final downloads = snapshot.data ?? [];

                if (downloads.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 100, bottom: 120),
                  physics: const BouncingScrollPhysics(),
                  itemCount: downloads.length,
                  itemBuilder: (context, index) {
                    return AnimatedListItem(
                      index: index,
                      child: _buildDownloadTile(context, downloads[index],
                          downloads, index, controller),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlayAllButton(BuildContext context) {
    return Consumer<EnhancedPlayerController>(
        builder: (context, controller, child) {
      return StreamBuilder(
          stream: controller.downloadService.downloadedSongsStream,
          builder: (context, snapshot) {
            final downloads = snapshot.data ?? [];
            if (downloads.isEmpty) return const SizedBox.shrink();

            return TextButton.icon(
              onPressed: () => controller.playPlaylist(downloads),
              icon: const Icon(Icons.play_circle_fill_rounded,
                  color: _accent, size: 28),
              label: const Text(
                'Play All',
                style: TextStyle(color: _accent, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: _accent.withOpacity(0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            );
          });
    });
  }

  Widget _buildDownloadTile(
      BuildContext context,
      SongModel song,
      List<SongModel> downloads,
      int index,
      EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentSong
            ? _accent.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentSong ? _accent.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.playPlaylist(downloads, startIndex: index),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Stack(
                  children: [
                    Hero(
                      tag: 'download_img_${song.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.grey[900]),
                        ),
                      ),
                    ),
                    if (isCurrentSong && controller.isPlaying)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: PlayingIndicator(size: 24, color: _accent),
                          ),
                        ),
                      ),
                    if (!isCurrentSong)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              size: 8, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCurrentSong)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: _accent.withOpacity(0.5), width: 0.5),
                          ),
                          child: const Text(
                            'PLAYING',
                            style: TextStyle(
                              color: _accent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Text(
                        song.title,
                        style: TextStyle(
                          color: isCurrentSong ? _accent : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6), fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white54),
                  onPressed: () => _showDeleteDialog(context, controller, song),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cloud_download_rounded,
                size: 64, color: Colors.white.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Downloads Yet',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Save songs to listen offline',
            style: TextStyle(color: Colors.white.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context,
      EnhancedPlayerController controller, SongModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Download',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${song.title}" from your device?',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              controller.downloadService.deleteDownload(song.id);
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFE50914))),
          ),
        ],
      ),
    );
  }
}
