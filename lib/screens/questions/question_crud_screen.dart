import 'package:flutter/material.dart';
import '../../repositories/question_repository.dart';
import '../../models/question.dart';
import 'question_card.dart';
import 'question_form.dart';

class QuestionCrudScreen extends StatefulWidget {
  const QuestionCrudScreen({super.key});
  @override
  State<QuestionCrudScreen> createState() => _QuestionCrudScreenState();
}

class _QuestionCrudScreenState extends State<QuestionCrudScreen> {
  final _repo = QuestionRepository();
  late Future<List<Question>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _repo.getAll();
  }

  Future<void> _openForm({Question? initial}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => QuestionForm(initial: initial),
    );
    if (res == true) {
      setState(() => _load());
    }
  }

  Future<void> _deleteQuestion(int id) async {
    final ok = await _repo.delete(id);

    final success = (ok as dynamic) == true || ok == 1;

    if (success) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Question Manager')),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('No questions'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => QuestionCard(
              question: items[i],
              onEdit: () => _openForm(initial: items[i]),
              onDelete: () => _deleteQuestion(items[i].questionID!),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _openForm(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
