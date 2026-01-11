import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/datasources/remote/youtube_service.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final YouTubeService _youtubeService = YouTubeService();
  List<SongModel> _trendingSongs = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTrendingSongs();
  }

  Future<void> _loadTrendingSongs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('HomeScreen: Starting to load trending songs...');
      final songs = await _youtubeService.getTrendingMusic();
      debugPrint('HomeScreen: Loaded ${songs.length} songs');
      setState(() {
        _trendingSongs = songs;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('HomeScreen: Error loading songs: $e');
      debugPrint('HomeScreen: Stack trace: $stack');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load songs. Check your connection.';
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeContent(),
              const SearchScreen(),
              const LibraryScreen(),
              const DownloadsScreen(),
            ],
          ),
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeContent() {
    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        final recentSongs = controller.getRecentlyPlayed(limit: 6);
        final favorites = controller.getFavorites();

        return RefreshIndicator(
          onRefresh: _loadTrendingSongs,
          color: const Color(0xFFE50914),
          backgroundColor: const Color(0xFF1A1A1A),
          edgeOffset: 100,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium App Bar with Glass effect
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: Colors.black.withOpacity(0.8),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  title: Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFE50914).withOpacity(0.2),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_outlined, size: 20),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              // Hero / Featured Section (First Trending Song)
              if (!_isLoading && _trendingSongs.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildHeroSection(_trendingSongs.first, controller),
                ),

              // Categories / Quick Access Chips
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _CategoryChip(label: 'All', isSelected: true),
                        _CategoryChip(label: 'Relax'),
                        _CategoryChip(label: 'Workout'),
                        _CategoryChip(label: 'Travel'),
                        _CategoryChip(label: 'Focus'),
                        _CategoryChip(label: 'Party'),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick Access Cards (Refined)
              SliverToBoxAdapter(
                child: _buildQuickAccessCards(controller),
              ),

              // Recently Played Section
              if (recentSongs.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildHorizontalSection(
                    title: 'Jump Back In',
                    songs: recentSongs,
                    controller: controller,
                    onSeeAll: () {
                      setState(() => _currentIndex = 2); // Go to Library
                    },
                  ),
                ),

              // Favorites Section
              if (favorites.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildHorizontalSection(
                    title: 'Your Favorites',
                    songs: favorites.take(6).toList(),
                    controller: controller,
                    onSeeAll: () {
                      setState(() => _currentIndex = 2); // Go to Library
                    },
                  ),
                ),

              // Popular Songs Section Header
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Trending Now',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      if (!_isLoading && _error == null)
                        IconButton(
                          icon: const Icon(Icons.refresh,
                              color: Colors.grey, size: 20),
                          onPressed: _loadTrendingSongs,
                        ),
                    ],
                  ),
                ),
              ),

              // Popular Songs List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (_isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                                color: Color(0xFFE50914)),
                          ),
                        );
                      }
                      if (_error != null) return _buildErrorState();
                      if (index >= _trendingSongs.length) return null;

                      // Skip first song as it is in Hero section
                      if (index == 0) return const SizedBox.shrink();

                      return _buildSongTile(_trendingSongs[index], controller);
                    },
                    childCount: _isLoading || _error != null
                        ? 1
                        : _trendingSongs.length,
                  ),
                ),
              ),

              // Bottom Padding for Mini Player
              const SliverPadding(padding: EdgeInsets.only(bottom: 160)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(
      SongModel song, EnhancedPlayerController controller) {
    return GestureDetector(
      onTap: () => _playSong(song, controller),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: CachedNetworkImageProvider(
                song.highResThumbnail ?? song.thumbnailUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE50914).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'FEATURED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    song.artist,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE50914),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSection({
    required String title,
    required List<SongModel> songs,
    required EnhancedPlayerController controller,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[400],
                    ),
                    child: const Text('More'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: songs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final song = songs[index];
                return _buildHorizontalSongCard(song, songs, index, controller);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSongCard(
    SongModel song,
    List<SongModel> songs,
    int index,
    EnhancedPlayerController controller,
  ) {
    final isCurrentSong = controller.currentSong?.id == song.id;

    return GestureDetector(
      onTap: () => controller.playPlaylist(songs, startIndex: index),
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (isCurrentSong)
                        BoxShadow(
                          color: const Color(0xFFE50914).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: song.thumbnailUrl,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[900],
                        child: Icon(Icons.music_note,
                            color: Colors.grey[800], size: 40),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        child: Icon(Icons.error, color: Colors.grey[800]),
                      ),
                    ),
                  ),
                ),
                if (isCurrentSong)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.graphic_eq,
                            color: Color(0xFFE50914), size: 40),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              song.title,
              style: TextStyle(
                color: isCurrentSong ? const Color(0xFFE50914) : Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              song.artist,
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCards(EnhancedPlayerController controller) {
    final playlists = controller.getAllPlaylists();
    final favorites = controller.getFavorites();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.favorite_rounded,
                  title: 'Favorites',
                  subtitle: '${favorites.length} songs',
                  color: const Color(0xFFE50914),
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickCard(
                  icon: Icons.playlist_play_rounded,
                  title: 'Playlists',
                  subtitle: '${playlists.length} playlists',
                  color: Colors.deepPurpleAccent,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadTrendingSongs,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(SongModel song, EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;
    final isFavorite = controller.isFavorite(song.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _playSong(song, controller),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrentSong
                  ? const Color(0xFFE50914).withOpacity(0.1)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: isCurrentSong
                  ? Border.all(color: const Color(0xFFE50914).withOpacity(0.3))
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: song.thumbnailUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[900],
                        ),
                      ),
                    ),
                    if (isCurrentSong)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.graphic_eq,
                            color: Color(0xFFE50914)),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          color: isCurrentSong
                              ? const Color(0xFFE50914)
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color:
                        isFavorite ? const Color(0xFFE50914) : Colors.grey[600],
                    size: 24,
                  ),
                  onPressed: () async {
                    final result = await controller.toggleFavorite(song);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result
                              ? 'Added to favorites'
                              : 'Removed from favorites'),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF1E1E1E),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey[600]),
                  onPressed: () => _showSongOptions(song, controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _playSong(SongModel song, EnhancedPlayerController controller) {
    controller.playPlaylist(_trendingSongs,
        startIndex: _trendingSongs.indexOf(song));
  }

  void _showSongOptions(SongModel song, EnhancedPlayerController controller) {
    final isFavorite = controller.isFavorite(song.id);
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
          const SizedBox(height: 8),
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
            title:
                Text(song.title, style: const TextStyle(color: Colors.white)),
            subtitle:
                Text(song.artist, style: TextStyle(color: Colors.grey[400])),
          ),
          const Divider(color: Colors.grey),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.white),
            title: const Text('Play', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              controller.playSong(song);
            },
          ),
          ListTile(
            leading: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? const Color(0xFFDC143C) : Colors.white,
            ),
            title: Text(
              isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () async {
              Navigator.pop(context);
              final result = await controller.toggleFavorite(song);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      result ? 'Added to favorites' : 'Removed from favorites'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.white),
            title: const Text('Add to Playlist',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistSheet(song, controller, playlists);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.white),
            title:
                const Text('Download', style: TextStyle(color: Colors.white)),
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

  void _showAddToPlaylistSheet(SongModel song,
      EnhancedPlayerController controller, List<PlaylistModel> playlists) {
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
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
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
            title: const Text('Create New Playlist',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showCreatePlaylistDialog(song, controller);
            },
          ),
          const Divider(color: Colors.grey),
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
                  final isInPlaylist =
                      playlist.songs.any((s) => s.id == song.id);

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
                              child: const Icon(Icons.playlist_play,
                                  color: Colors.white54),
                            ),
                    ),
                    title: Text(playlist.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      '${playlist.songs.length} songs',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: isInPlaylist
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFFDC143C))
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      if (isInPlaylist) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Song already in this playlist')),
                        );
                      } else {
                        await controller.addSongToPlaylist(playlist.id, song);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Added to "${playlist.name}"')),
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

  void _showCreatePlaylistDialog(
      SongModel song, EnhancedPlayerController controller) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Create Playlist',
            style: TextStyle(color: Colors.white)),
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
                    content:
                        Text('Created "${nameController.text}" and added song'),
                    backgroundColor: const Color(0xFFDC143C),
                  ),
                );
              }
            },
            child: const Text('Create',
                style: TextStyle(color: Color(0xFFDC143C))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      backgroundColor: const Color(0xFF1A1A1A),
      selectedItemColor: const Color(0xFFDC143C),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.library_music),
          label: 'Library',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.download_done),
          label: 'Downloads',
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFE50914)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFE50914)
                    : Colors.white.withOpacity(0.1),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
