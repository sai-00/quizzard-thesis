import 'package:flutter/material.dart';
import '../../repositories/question_repository.dart';
import '../../models/question.dart';
import 'question_card.dart';

class QuestionList extends StatelessWidget {
  const QuestionList({super.key});
  @override
  Widget build(BuildContext context) {
    final repo = QuestionRepository();
    return FutureBuilder<List<Question>>(
      future: repo.getAll(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No questions'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) => QuestionCard(question: items[i]),
        );
      },
    );
  }
}
