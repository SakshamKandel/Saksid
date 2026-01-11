import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import '../../widgets/animated_list_item.dart';
import '../../widgets/playing_indicator.dart';
import '../../../data/datasources/remote/youtube_service.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../controllers/enhanced_player_controller.dart';

/// SakSid Music - Glass Search Screen
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final YouTubeService _youtubeService = YouTubeService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<SongModel> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  Timer? _debounce;
  final List<String> _recentSearches = [];

  static const Color _accent = Color(0xFFE50914);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _youtubeService.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _error = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _youtubeService.searchSongs('$query music');
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });

        if (!_recentSearches.contains(query)) {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 5) _recentSearches.removeLast();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Search failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Dynamic Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.black, Color(0xFF050505), Colors.black],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(color: Colors.black.withOpacity(0.8)),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Floating Glass Search Bar
                _buildGlassSearchBar(),

                const SizedBox(height: 16),

                // Content Area
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search songs, artists...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
              prefixIcon: const Icon(Icons.search_rounded, color: _accent),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchResults = [];
                          _error = null;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            cursorColor: _accent,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: const AlwaysStoppedAnimation<Color>(_accent),
          strokeWidth: 3,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No results found',
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
      );
    }

    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          physics: const BouncingScrollPhysics(),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final song = _searchResults[index];
            return AnimatedListItem(
              index: index,
              child: _buildSongTile(song, controller, index),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Text(
              'Recent',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map((query) => _buildGlassChip(query))
                  .toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Categories
          Text(
            'Browse',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _buildCategoryCard('Pop', const Color(0xFFE91E63)),
              _buildCategoryCard('Hip Hop', const Color(0xFFFFA726)),
              _buildCategoryCard('Rock', const Color(0xFFD32F2F)),
              _buildCategoryCard('EDM', const Color(0xFF9C27B0)),
              _buildCategoryCard('lo-fi', const Color(0xFF26A69A)),
              _buildCategoryCard('Indie', const Color(0xFF5C6BC0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassChip(String label) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, color: Colors.white54, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style:
                  TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String label, Color color) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.4),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Transform.rotate(
                  angle: 0.4,
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 100,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSongTile(
      SongModel song, EnhancedPlayerController controller, int index) {
    final isCurrentSong = controller.currentSong?.id == song.id;
    final isFavorite = controller.isFavorite(song.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrentSong ? _accent.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border:
            isCurrentSong ? Border.all(color: _accent.withOpacity(0.3)) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.playPlaylist(_searchResults,
              startIndex: _searchResults.indexOf(song)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Hero(
                      tag: 'search_img_${song.id}',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: Colors.white10),
                        ),
                      ),
                    ),
                    if (isCurrentSong && controller.isPlaying)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: PlayingIndicator(size: 20, color: _accent),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
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
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              song.title,
                              style: TextStyle(
                                color: isCurrentSong ? _accent : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artist,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 13),
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
                    color: isFavorite ? _accent : Colors.white24,
                    size: 22,
                  ),
                  onPressed: () => controller.toggleFavorite(song),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: Colors.white24),
                  onPressed: () => _showSongOptions(song, controller),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSongOptions(SongModel song, EnhancedPlayerController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.playlist_add_rounded, color: Colors.white),
              title: const Text('Add to Playlist',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.white),
              title:
                  const Text('Download', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                controller.downloadSong(song);
              },
            ),
            const SizedBox(height: 20),
          ])),
    );
  }

  Widget _buildErrorState() {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline_rounded,
          size: 60, color: Colors.white.withOpacity(0.2)),
      const SizedBox(height: 16),
      Text(_error ?? 'Something went wrong',
          style: const TextStyle(color: Colors.white54)),
      const SizedBox(height: 24),
      TextButton(
        onPressed: () => _performSearch(_searchController.text),
        child: const Text('Retry', style: TextStyle(color: _accent)),
      )
    ]));
  }
}
