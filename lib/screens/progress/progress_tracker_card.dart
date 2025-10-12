import 'package:flutter/material.dart';
import '../../models/progress.dart';

class ProgressTrackerCard extends StatelessWidget {
  final Progress progress;
  const ProgressTrackerCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('Q ${progress.questionID} — ${progress.progressLevel ?? ''}'),
      subtitle: Text('Played: ${progress.datePlayed ?? ''}'),
      trailing: Text(progress.isCorrect == 1 ? '✓' : '✗'),
    );
  }
}
