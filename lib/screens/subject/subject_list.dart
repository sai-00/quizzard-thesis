import 'package:flutter/material.dart';
import '../../repositories/question_repository.dart';
import 'subject_card.dart';

class SubjectList extends StatelessWidget {
  final int profileId;
  const SubjectList({super.key, required this.profileId});

  @override
  Widget build(BuildContext context) {
    final repo = QuestionRepository();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.getSubjects(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final subjects = snap.data ?? [];
        if (subjects.isEmpty) {
          return const Center(child: Text('No subjects'));
        }
        return ListView.builder(
          itemCount: subjects.length,
          itemBuilder: (context, i) {
            final subj = subjects[i];
            return SubjectCard(
              subjID: subj['subjID'] as int,
              subjName: subj['subjName'] as String,
              profileId: profileId,
            );
          },
        );
      },
    );
  }
}
