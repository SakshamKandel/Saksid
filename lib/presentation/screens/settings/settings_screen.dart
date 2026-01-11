import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../di/injection_container.dart';
import '../../../services/storage/local_storage_service.dart';
import '../../../services/playlist/playlist_service.dart';
import '../../controllers/enhanced_player_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late LocalStorageService _storageService;
  late AudioQuality _audioQuality;
  late AudioQuality _downloadQuality;
  late bool _autoPlay;
  late bool _crossfade;
  late int _crossfadeDuration;
  late bool _normalizeVolume;
  late bool _downloadOverWifi;

  @override
  void initState() {
    super.initState();
    _storageService = sl<LocalStorageService>();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _audioQuality = _storageService.getAudioQuality();
      _downloadQuality = _storageService.getDownloadQuality();
      _autoPlay = _storageService.getAutoPlay();
      _crossfade = _storageService.getCrossfade();
      _crossfadeDuration = _storageService.getCrossfadeDuration();
      _normalizeVolume = _storageService.getNormalizeVolume();
      _downloadOverWifi = _storageService.getDownloadOverWifi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // Audio Section
          _buildSectionHeader('Audio'),
          _buildAudioQualityTile(),
          _buildSwitchTile(
            title: 'Auto Play',
            subtitle: 'Start playing next song automatically',
            value: _autoPlay,
            onChanged: (value) async {
              await _storageService.setAutoPlay(value);
              setState(() => _autoPlay = value);
            },
          ),
          _buildSwitchTile(
            title: 'Crossfade',
            subtitle: 'Smooth transition between songs',
            value: _crossfade,
            onChanged: (value) async {
              await _storageService.setCrossfade(value);
              setState(() => _crossfade = value);
            },
          ),
          if (_crossfade) _buildCrossfadeDurationTile(),
          _buildSwitchTile(
            title: 'Normalize Volume',
            subtitle: 'Consistent volume across all songs',
            value: _normalizeVolume,
            onChanged: (value) async {
              await _storageService.setNormalizeVolume(value);
              setState(() => _normalizeVolume = value);
            },
          ),

          // Downloads Section
          _buildSectionHeader('Downloads'),
          _buildDownloadQualityTile(),
          _buildSwitchTile(
            title: 'Download over WiFi only',
            subtitle: 'Save mobile data',
            value: _downloadOverWifi,
            onChanged: (value) async {
              await _storageService.setDownloadOverWifi(value);
              setState(() => _downloadOverWifi = value);
            },
          ),

          // Storage Section
          _buildSectionHeader('Storage'),
          _buildTile(
            icon: Icons.cached,
            title: 'Clear Cache',
            subtitle: 'Clear cached images and data',
            onTap: () => _showClearCacheDialog(),
          ),
          _buildTile(
            icon: Icons.history,
            title: 'Clear Recently Played',
            subtitle: 'Clear your listening history',
            onTap: () => _showClearHistoryDialog(),
          ),

          // About Section
          _buildSectionHeader('About'),
          _buildTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () => _launchUrl('https://example.com/privacy'),
          ),
          _buildTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            onTap: () => _launchUrl('https://example.com/terms'),
          ),
          _buildTile(
            icon: Icons.code,
            title: 'Open Source Licenses',
            subtitle: 'Third-party licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'SakSid Music',
              applicationVersion: '1.0.0',
            ),
          ),

          // Reset Section
          _buildSectionHeader('Reset'),
          _buildTile(
            icon: Icons.restore,
            title: 'Reset Settings',
            subtitle: 'Reset all settings to default',
            onTap: () => _showResetSettingsDialog(),
            iconColor: Colors.orange,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFDC143C),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[400])),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFDC143C),
    );
  }

  Widget _buildAudioQualityTile() {
    return ListTile(
      leading: const Icon(Icons.high_quality, color: Colors.white),
      title: const Text('Streaming Quality',
          style: TextStyle(color: Colors.white)),
      subtitle: Text(
        _getQualityLabel(_audioQuality),
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => _showAudioQualityDialog(),
    );
  }

  Widget _buildDownloadQualityTile() {
    return ListTile(
      leading: const Icon(Icons.download, color: Colors.white),
      title:
          const Text('Download Quality', style: TextStyle(color: Colors.white)),
      subtitle: Text(
        _getQualityLabel(_downloadQuality),
        style: TextStyle(color: Colors.grey[400]),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => _showDownloadQualityDialog(),
    );
  }

  Widget _buildCrossfadeDurationTile() {
    return ListTile(
      leading: const SizedBox(width: 24),
      title: const Text('Crossfade Duration',
          style: TextStyle(color: Colors.white)),
      subtitle: Slider(
        value: _crossfadeDuration.toDouble(),
        min: 1,
        max: 12,
        divisions: 11,
        activeColor: const Color(0xFFDC143C),
        inactiveColor: Colors.grey[700],
        label: '${_crossfadeDuration}s',
        onChanged: (value) async {
          final duration = value.toInt();
          await _storageService.setCrossfadeDuration(duration);
          setState(() => _crossfadeDuration = duration);
        },
      ),
      trailing: Text(
        '${_crossfadeDuration}s',
        style: TextStyle(color: Colors.grey[400]),
      ),
    );
  }

  String _getQualityLabel(AudioQuality quality) {
    switch (quality) {
      case AudioQuality.low:
        return 'Low (128 kbps) - Less data usage';
      case AudioQuality.medium:
        return 'Medium (192 kbps) - Balanced';
      case AudioQuality.high:
        return 'High (320 kbps) - Best quality';
    }
  }

  void _showAudioQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Streaming Quality',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AudioQuality.values.map((quality) {
            return RadioListTile<AudioQuality>(
              title: Text(_getQualityLabel(quality),
                  style: const TextStyle(color: Colors.white)),
              value: quality,
              groupValue: _audioQuality,
              activeColor: const Color(0xFFDC143C),
              onChanged: (value) async {
                if (value != null) {
                  await _storageService.setAudioQuality(value);
                  setState(() => _audioQuality = value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDownloadQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Download Quality',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AudioQuality.values.map((quality) {
            return RadioListTile<AudioQuality>(
              title: Text(_getQualityLabel(quality),
                  style: const TextStyle(color: Colors.white)),
              value: quality,
              groupValue: _downloadQuality,
              activeColor: const Color(0xFFDC143C),
              onChanged: (value) async {
                if (value != null) {
                  await _storageService.setDownloadQuality(value);
                  setState(() => _downloadQuality = value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Clear Cache', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will clear all cached images and data. Downloaded songs will not be affected.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await DefaultCacheManager().emptyCache();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully'),
                    backgroundColor: Color(0xFFDC143C),
                  ),
                );
              }
            },
            child:
                const Text('Clear', style: TextStyle(color: Color(0xFFDC143C))),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Text('Clear History', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will clear your recently played songs history.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final controller = context.read<EnhancedPlayerController>();
              await controller.clearRecentlyPlayed();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('History cleared'),
                    backgroundColor: Color(0xFFDC143C),
                  ),
                );
              }
            },
            child:
                const Text('Clear', style: TextStyle(color: Color(0xFFDC143C))),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Text('Reset Settings', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will reset all settings to their default values. Your playlists, favorites, and downloads will not be affected.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _storageService.clearAll();
              _loadSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to default'),
                    backgroundColor: Color(0xFFDC143C),
                  ),
                );
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
