import 'package:flutter/material.dart';
import 'difficulty.dart';

class SubjectContent extends StatelessWidget {
  final int subjID;
  final String subjName;
  final int profileId;

  const SubjectContent({
    super.key,
    required this.subjID,
    required this.subjName,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subjName)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select a difficulty to start playing "$subjName".',
              // subtitle1 was removed in newer Flutter; use titleMedium for compatibility
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: DifficultyChooser(
              subjID: subjID,
              subjName: subjName,
              profileId: profileId,
            ),
          ),
        ],
      ),
    );
  }
}
