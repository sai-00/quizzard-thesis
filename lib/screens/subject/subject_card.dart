import 'package:flutter/material.dart';
import 'subject_content.dart' as sc;

class SubjectCard extends StatelessWidget {
  final int subjID;
  final String subjName;
  final int profileId;
  const SubjectCard({
    super.key,
    required this.subjID,
    required this.subjName,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(subjName),
        trailing: const Icon(Icons.play_arrow),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => sc.SubjectContent(
              subjID: subjID,
              subjName: subjName,
              profileId: profileId,
            ),
          ),
        ),
      ),
    );
  }
}
