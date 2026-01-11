import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/datasources/remote/youtube_service.dart';
import '../../../data/models/song_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../controllers/enhanced_player_controller.dart';

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

  // Recent searches (could be persisted later)
  final List<String> _recentSearches = [];

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
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
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Search failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: 'Search for songs, artists...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _error = null;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _performSearch(value);
                    _focusNode.unfocus();
                  }
                },
              ),
            ),

            // Content
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFDC143C)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _performSearch(_searchController.text),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              'No results found for "${_searchController.text}"',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Consumer<EnhancedPlayerController>(
      builder: (context, controller, child) {
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 160),
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final song = _searchResults[index];
            return _buildSongTile(song, controller);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _recentSearches.clear()),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Color(0xFFDC143C)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches
                  .map((query) => ActionChip(
                        label: Text(query),
                        backgroundColor: const Color(0xFF2A2A2A),
                        labelStyle: const TextStyle(color: Colors.white),
                        onPressed: () {
                          _searchController.text = query;
                          _performSearch(query);
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Browse Categories
          const Text(
            'Browse Categories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildCategoryChip('Pop', Colors.pink),
              _buildCategoryChip('Hip Hop', Colors.orange),
              _buildCategoryChip('Rock', Colors.red),
              _buildCategoryChip('EDM', Colors.purple),
              _buildCategoryChip('R&B', Colors.blue),
              _buildCategoryChip('Jazz', Colors.teal),
              _buildCategoryChip('Classical', Colors.brown),
              _buildCategoryChip('Bollywood', Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color color) {
    return GestureDetector(
      onTap: () {
        _searchController.text = label;
        _performSearch(label);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongTile(SongModel song, EnhancedPlayerController controller) {
    final isCurrentSong = controller.currentSong?.id == song.id;
    final isFavorite = controller.isFavorite(song.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: isCurrentSong ? const Color(0xFFDC143C).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            controller.playPlaylist(_searchResults, startIndex: _searchResults.indexOf(song));
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnailUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.music_note, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(
                          color: isCurrentSong ? const Color(0xFFDC143C) : Colors.white,
                          fontWeight: FontWeight.w500,
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
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? const Color(0xFFDC143C) : Colors.white54,
                    size: 20,
                  ),
                  onPressed: () async {
                    final result = await controller.toggleFavorite(song);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result ? 'Added to favorites' : 'Removed from favorites'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
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
            title: Text(song.title, style: const TextStyle(color: Colors.white)),
            subtitle: Text(song.artist, style: TextStyle(color: Colors.grey[400])),
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
                  content: Text(result ? 'Added to favorites' : 'Removed from favorites'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add, color: Colors.white),
            title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showAddToPlaylistSheet(song, controller, playlists);
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

  void _showAddToPlaylistSheet(SongModel song, EnhancedPlayerController controller, List<PlaylistModel> playlists) {
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

  void _showCreatePlaylistDialog(SongModel song, EnhancedPlayerController controller) {
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

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _focusNode.dispose();
    _youtubeService.dispose();
    super.dispose();
  }
}
