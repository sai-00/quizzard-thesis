import 'dart:io';

import 'package:flutter/material.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/question_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../models/user.dart';
import '../../models/progress.dart';
import 'icon_selection.dart';

class AddProfileForm extends StatefulWidget {
  const AddProfileForm({super.key});

  @override
  State<AddProfileForm> createState() => _AddProfileFormState();
}

class _AddProfileFormState extends State<AddProfileForm> {
  final _form = GlobalKey<FormState>();
  String _name = '';
  final TextEditingController _nameController = TextEditingController();
  bool _nameExists = false;
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
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              if (_nameExists)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'User exists, enter a different name',
                    style: TextStyle(color: Colors.red),
                  ),
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
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: _avatarPath!.startsWith('assets/')
                            ? Image.asset(_avatarPath!, fit: BoxFit.cover)
                            : Image.file(File(_avatarPath!), fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _avatarPath!.split('/').last,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
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

    setState(() {
      _saving = true;
      _nameExists = false;
    });

    final userRepo = UserRepository();
    final questionRepo = QuestionRepository();
    final progressRepo = ProgressRepository();

    bool creationFailed = false;

    try {
      // check duplicate name (case-insensitive) and limit
      final users = await userRepo.getAll();
      if (users.length >= 35) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile limit reached (35)')),
        );
        setState(() => _saving = false);
        return;
      }
      final exists = users.any(
        (u) => u.name.toLowerCase() == _name.toLowerCase(),
      );
      if (exists) {
        if (!mounted) return;
        setState(() => _nameExists = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User exists, enter a different name')),
        );
        setState(() => _saving = false);
        return;
      }

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

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (_nameExists && _nameController.text.trim().isNotEmpty) {
        setState(() => _nameExists = false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture() async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (c) => const IconSelection(),
    );
    if (selected != null && selected.isNotEmpty) {
      setState(() => _avatarPath = selected);
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
