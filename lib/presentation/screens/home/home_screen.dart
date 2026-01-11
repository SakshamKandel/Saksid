import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../../data/datasources/remote/youtube_service.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/listener_badge.dart';
import '../../controllers/enhanced_player_controller.dart';
import '../player/mini_player.dart';
import '../search/search_screen.dart';
import '../downloads/downloads_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final YouTubeService _youtubeService = YouTubeService();
  List<SongModel> _songs = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Demo listening stats
  final int _listeningMinutes = 720;

  late AnimationController _shimmerController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _loadSongs();

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    try {
      final songs = await _youtubeService.getTrendingMusic();
      setState(() {
        _songs = songs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0F),
        body: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1A1A2E),
                      const Color(0xFF0A0A0F),
                      const Color(0xFF0A0A0F),
                    ],
                    stops: const [0.0, 0.3, 1.0],
                  ),
                ),
              ),
            ),
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeContent(),
                const SearchScreen(),
                const LibraryScreen(),
                const DownloadsScreen(),
              ],
            ),
            // Mini Player
            const Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
        bottomNavigationBar: _buildPremiumBottomNav(),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        final badge = ListenerBadge.fromListeningHours(_listeningMinutes ~/ 60);

        return RefreshIndicator(
          onRefresh: _loadSongs,
          color: const Color(0xFF6366F1),
          backgroundColor: const Color(0xFF1A1A2E),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // === PREMIUM HEADER ===
              SliverToBoxAdapter(
                child: _buildPremiumHeader(badge),
              ),

              // === QUICK ACTIONS ===
              SliverToBoxAdapter(
                child: _buildQuickActions(controller),
              ),

              // === FEATURED SECTION ===
              if (!_isLoading && _songs.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildFeaturedCard(_songs.first, controller),
                ),

              // === FOR YOU SECTION ===
              SliverToBoxAdapter(
                child: _buildForYouSection(),
              ),

              // === TRENDING TRACKS ===
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trending Now',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up,
                                color: Color(0xFF6366F1), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'See all',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // === SONG LIST ===
              _isLoading
                  ? SliverToBoxAdapter(child: _buildLoadingState())
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= _songs.length || index == 0)
                              return null;
                            return _buildSongCard(
                                _songs[index], index, controller);
                          },
                          childCount: _songs.length,
                        ),
                      ),
                    ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 180)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPremiumHeader(ListenerBadge badge) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
      child: Row(
        children: [
          // Profile Avatar with Badge
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _getBadgeColor(badge.tier),
                    _getBadgeColor(badge.tier).withOpacity(0.5),
                  ],
                ),
              ),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A2E),
                  border: Border.all(color: const Color(0xFF0A0A0F), width: 2),
                ),
                child:
                    const Icon(Icons.person, color: Colors.white70, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'Music Lover',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(badge.tier).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getBadgeColor(badge.tier).withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getBadgeIcon(badge.tier),
                            color: _getBadgeColor(badge.tier),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            badge.tier.name.toUpperCase(),
                            style: TextStyle(
                              color: _getBadgeColor(badge.tier),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Notification
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                color: Colors.white70, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(EnhancedPlayerController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.shuffle_rounded,
              label: 'Shuffle',
              gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              onTap: () {
                if (_songs.isNotEmpty) {
                  final shuffled = List<SongModel>.from(_songs)..shuffle();
                  controller.playPlaylist(shuffled, startIndex: 0);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.favorite_rounded,
              label: 'Liked',
              gradient: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
              onTap: () => setState(() => _currentIndex = 2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.history_rounded,
              label: 'Recent',
              gradient: const [Color(0xFF10B981), Color(0xFF059669)],
              onTap: () => setState(() => _currentIndex = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient[0].withOpacity(0.2),
              gradient[1].withOpacity(0.1)
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: gradient[0].withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(
      SongModel song, EnhancedPlayerController controller) {
    return GestureDetector(
      onTap: () => controller.playSong(song),
      child: Container(
        margin: const EdgeInsets.all(20),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              CachedNetworkImage(
                imageUrl: song.highResThumbnail ?? song.thumbnailUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A2E),
                  child: const Icon(Icons.music_note,
                      color: Colors.white24, size: 64),
                ),
              ),
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🔥 FEATURED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Play Button
              Positioned(
                right: 20,
                bottom: 20,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.5),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForYouSection() {
    final mixes = [
      {
        'title': 'Daily Mix',
        'sub': 'Your vibe',
        'color1': 0xFF6366F1,
        'color2': 0xFF8B5CF6
      },
      {
        'title': 'Discover',
        'sub': 'New finds',
        'color1': 0xFF06B6D4,
        'color2': 0xFF0EA5E9
      },
      {
        'title': 'Chill',
        'sub': 'Relax',
        'color1': 0xFF10B981,
        'color2': 0xFF059669
      },
      {
        'title': 'Energy',
        'sub': 'Workout',
        'color1': 0xFFEC4899,
        'color2': 0xFFF43F5E
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'Made for you',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: mixes.length,
            itemBuilder: (context, index) {
              final mix = mixes[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(mix['color1'] as int),
                      Color(mix['color2'] as int),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color(mix['color1'] as int).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.music_note_rounded,
                          color: Colors.white70, size: 28),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mix['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            mix['sub'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSongCard(
      SongModel song, int index, EnhancedPlayerController controller) {
    final isPlaying = controller.currentSong?.id == song.id;

    return GestureDetector(
      onTap: () => controller.playSong(song),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPlaying
              ? const Color(0xFF6366F1).withOpacity(0.15)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying
                ? const Color(0xFF6366F1).withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF1A1A2E),
                    child: const Icon(Icons.music_note, color: Colors.white24),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isPlaying ? const Color(0xFF6366F1) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            // Actions
            if (isPlaying)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.equalizer_rounded,
                    color: Colors.white, size: 18),
              )
            else
              Icon(
                Icons.play_circle_filled_rounded,
                color: Colors.white.withOpacity(0.5),
                size: 36,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF6366F1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading tracks...',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F).withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.search_rounded, 'Search', 1),
              _buildNavItem(Icons.library_music_rounded, 'Library', 2),
              _buildNavItem(Icons.download_rounded, 'Downloads', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(ListenerTier tier) {
    switch (tier) {
      case ListenerTier.bronze:
        return const Color(0xFFCD7F32);
      case ListenerTier.silver:
        return const Color(0xFFC0C0C0);
      case ListenerTier.gold:
        return const Color(0xFFFFD700);
      case ListenerTier.platinum:
        return const Color(0xFFE5E4E2);
      case ListenerTier.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  IconData _getBadgeIcon(ListenerTier tier) {
    switch (tier) {
      case ListenerTier.bronze:
        return Icons.music_note;
      case ListenerTier.silver:
        return Icons.headphones;
      case ListenerTier.gold:
        return Icons.stars;
      case ListenerTier.platinum:
        return Icons.auto_awesome;
      case ListenerTier.diamond:
        return Icons.diamond;
    }
  }
}
