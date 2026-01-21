import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  String? _avatarPath;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _pickProfilePicture,
                  child: const Text('Pick profile picture'),
                ),
              ),
              if (_avatarPath != null && _avatarPath!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _avatarPath!.split(Platform.pathSeparator).last,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      insetPadding: const EdgeInsets.all(24),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
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
      final newId = await userRepo.add(
        User(name: _name, avatar: _avatarPath ?? ''),
      );
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

  Future<void> _pickProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        setState(() => _avatarPath = path);
      }
    }
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
