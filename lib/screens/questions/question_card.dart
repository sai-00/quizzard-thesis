import 'package:flutter/material.dart';
import '../../models/question.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const QuestionCard({
    super.key,
    required this.question,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(question.questionText),
        subtitle: Text('Difficulty: ${question.difficulty ?? 'N/A'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
