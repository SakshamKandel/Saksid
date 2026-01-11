import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import '../../controllers/enhanced_player_controller.dart';
import '../../widgets/animated_list_item.dart';
import '../../widgets/playing_indicator.dart';
import '../../../data/models/song_model.dart';
import '../../../data/datasources/remote/youtube_service.dart';
import '../../../services/stats/stats_service.dart';
import '../../../data/models/listener_badge.dart';

/// SakSid Music - Glass Home Screen
class HomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;

  const HomeScreen({
    super.key,
    this.onTabChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final YouTubeService _youtubeService = YouTubeService();
  List<SongModel> _trendingSongs = [];
  bool _isLoading = true;

  static const Color _accent = Color(0xFFE50914);

  @override
  void initState() {
    super.initState();
    _loadTrendingMusic();
  }

  Future<void> _loadTrendingMusic() async {
    try {
      // Load trending songs
      final songs = await _youtubeService.searchSongs('Global Top 50');
      if (mounted) {
        setState(() {
          _trendingSongs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading trending: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _youtubeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Color(0xFF0F0F0F)],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildGreetingSection()),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _accent),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _trendingSongs.length)
                      return const SizedBox(height: 120);
                    return AnimatedListItem(
                      index: index,
                      child:
                          _buildSongRow(context, _trendingSongs[index], index),
                    );
                  },
                  childCount: _trendingSongs.length + 1,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      expandedHeight: 80,
      floating: true,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.only(left: 20, bottom: 16),
            child: Row(
              children: [
                const Text(
                  'SakSid',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const Text(
                  'Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon:
                      const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good Evening',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildTierCard(),
          const SizedBox(height: 32),
          // Jump Back In Section
          _buildSectionHeader('Jump Back In'),
          const SizedBox(height: 16),
          _buildHorizontalList(),
          const SizedBox(height: 32),
          // New Releases Section
          _buildSectionHeader('New Releases'),
          const SizedBox(height: 16),
          _buildHorizontalList(isNew: true),
          const SizedBox(height: 32),
          _buildSectionHeader('Trending Now'),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildHorizontalList({bool isNew = false}) {
    // Determine source based on isNew.
    // For 'Jump Back In', we'd ideally use history. For now using trending subset.
    // For 'New Releases', using another subset.
    final songs = _trendingSongs.take(5).toList();
    if (isNew && _trendingSongs.length > 5) {
      songs.clear();
      songs.addAll(_trendingSongs.skip(5).take(5));
    }

    if (songs.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTierCard() {
    return Consumer<StatsService>(builder: (context, stats, child) {
      final badge = stats.badge;
      final isDiamond = badge.tier == ListenerTier.diamond;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accent.withOpacity(0.8), _accent.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Icon(
                  isDiamond ? Icons.workspace_premium : Icons.auto_awesome,
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              badge.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            if (!isDiamond) ...[
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${stats.totalHours.toStringAsFixed(1)} hrs',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'NEXT: ${badge.nextTierHours} HRS',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6), fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      backgroundColor: Colors.black.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildSongRow(BuildContext context, SongModel song, int index) {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        final isCurrentSong = controller.currentSong?.id == song.id;

        return GestureDetector(
          onTap: () =>
              controller.playPlaylist(_trendingSongs, startIndex: index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isCurrentSong
                      ? _accent.withOpacity(0.3)
                      : Colors.transparent),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Index
                SizedBox(
                  width: 30,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isCurrentSong ? _accent : Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 12),

                // Art
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: song.thumbnailUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isCurrentSong && controller.isPlaying)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: PlayingIndicator(size: 16, color: _accent),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isCurrentSong)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: _accent.withOpacity(0.5),
                                    width: 0.5),
                              ),
                              child: const Text(
                                'PLAYING',
                                style: TextStyle(
                                  color: _accent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              song.title,
                              style: TextStyle(
                                color: isCurrentSong ? _accent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white54),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
