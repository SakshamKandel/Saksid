import 'dart:ui';
import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'library/library_screen.dart';
import 'downloads/downloads_screen.dart';
import 'player/mini_player.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  static const Color _accent = Color(0xFFE50914);

  final List<Widget> _screens = [
    // We will update HomeScreen to NOT require the callback or ignore it for now
    // Actually we need to fix HomeScreen signature or pass a dummy if we change it.
    // For now, let's assume we pass the callback but handle navigation here.
    const HomeScreenWrapper(),
    const SearchScreen(),
    const LibraryScreen(),
    const DownloadsScreen(),
  ];

  void _onTabChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // 2. Mini Player (Positioned above Nav Bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 100, // Height of Nav Bar + padding
            child: const MiniPlayer(),
          ),

          // 3. Navigation Bar (Glass)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildGlassNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNavBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          decoration: BoxDecoration(
            color:
                Colors.black.withOpacity(0.8), // Slightly darker for contrast
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.search_rounded, 'Search', 1),
              _buildNavItem(Icons.library_music_rounded, 'Library', 2),
              _buildNavItem(Icons.download_rounded, 'Offline', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabChange(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: _accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? _accent : Colors.white54,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

// Temporary wrapper to adapt HomeScreen
class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    // We instantiate HomeScreen. We can pass a dummy callback since MainWrapper handles nav via its own UI
    return HomeScreen(onTabChange: (_) {});
  }
}
