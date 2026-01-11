import 'package:flutter/material.dart';

class LibraryTab extends StatelessWidget {
  final IconData icon;
  final String text;

  const LibraryTab({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}
