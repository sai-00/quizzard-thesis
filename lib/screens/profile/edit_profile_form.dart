// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../repositories/user_repository.dart';
import '../../models/user.dart';

class EditProfileForm extends StatefulWidget {
  final int profileId;
  const EditProfileForm({super.key, required this.profileId});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _form = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _avatarPath;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final repo = UserRepository();
    final users = await repo.getAll();
    final user = users.firstWhere(
      (u) => u.profileID == widget.profileId,
      orElse: () => User(profileID: widget.profileId, name: ''),
    );
    if (!mounted) return;
    _nameController.text = user.name;
    _avatarPath = user.avatar;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: _loading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter a name'
                          : null,
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) setState(() => _avatarPath = path);
    }
  }

  Future<void> _handleSave() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = UserRepository();
    final updated = User(
      profileID: widget.profileId,
      name: _nameController.text.trim(),
      avatar: _avatarPath ?? '',
    );
    try {
      await repo.update(updated);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    }
  }
}
