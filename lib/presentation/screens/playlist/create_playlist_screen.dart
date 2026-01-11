import 'package:flutter/material.dart';

class CreatePlaylistScreen extends StatelessWidget {
  const CreatePlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Playlist')),
      body: const Center(child: Text('Create Playlist Form')),
    );
  }
}
