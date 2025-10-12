import 'package:flutter/material.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/question_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../models/user.dart';
import '../../models/progress.dart';

class AddProfileForm extends StatefulWidget {
  const AddProfileForm({super.key});

  @override
  State<AddProfileForm> createState() => _AddProfileFormState();
}

class _AddProfileFormState extends State<AddProfileForm> {
  final _form = GlobalKey<FormState>();
  String _name = '';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Profile'),
      content: Form(
        key: _form,
        child: TextFormField(
          decoration: const InputDecoration(labelText: 'Name'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          onSaved: (v) => _name = v!.trim(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(false), // ❗return false when canceled
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _handleAddPressed,
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _handleAddPressed() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    setState(() => _saving = true);

    final userRepo = UserRepository();
    final questionRepo = QuestionRepository();
    final progressRepo = ProgressRepository();

    bool creationFailed = false;

    try {
      final newId = await userRepo.add(User(name: _name));
      final subjects = await questionRepo.getSubjects();

      for (final subj in subjects) {
        try {
          final subjID = subj['subjID'] as int;
          final questions = await questionRepo.getBySubject(subjID);
          if (questions.isNotEmpty) {
            final firstQ = questions.first;
            final prog = Progress(
              profileID: newId,
              subjID: subjID,
              questionID: firstQ.questionID!,
              datePlayed: DateTime.now().toIso8601String(),
              progressLevel: 'Not started',
              isCorrect: 0,
              points: 0,
            );
            await progressRepo.add(prog);
          }
        } catch (e) {
          debugPrint(
            'Warning: failed to create initial progress for subject: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      creationFailed = true;
    }

    if (!mounted) return;

    _handleResult(creationFailed);
  }

  void _handleResult(bool creationFailed) {
    setState(() => _saving = false);

    if (creationFailed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create profile')));
    } else {
      Navigator.of(context).pop(true);
    }
  }
}
