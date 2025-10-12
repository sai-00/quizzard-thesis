import 'package:flutter/material.dart';

class PlayButton extends StatelessWidget {
  final VoidCallback onPlay;
  const PlayButton({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.play_arrow),
      label: const Text('Play'),
      onPressed: onPlay,
    );
  }
}
