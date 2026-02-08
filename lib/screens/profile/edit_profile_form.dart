// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'icon_selection.dart';
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
  bool _nameExists = false;
  String? _avatarPath;
  bool _loading = true;
  bool _saving = false;
  bool _isAdmin = false;
  String? _adminPasscode;

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
    _isAdmin = user.isAdmin == true;
    _adminPasscode = user.adminPasscode;
    setState(() => _loading = false);
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
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
                                  : Image.file(
                                      File(_avatarPath!),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _avatarPath!.split('/').last,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
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
    final selected = await showDialog<String?>(
      context: context,
      builder: (c) => const IconSelection(),
    );
    if (selected != null && selected.isNotEmpty) {
      setState(() => _avatarPath = selected);
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
      isAdmin: _isAdmin,
      adminPasscode: _adminPasscode,
    );
    try {
      // check duplicate names among other users
      final users = await repo.getAll();
      final exists = users.any(
        (u) =>
            u.profileID != widget.profileId &&
            u.name.toLowerCase() == updated.name.toLowerCase(),
      );
      if (exists) {
        if (!mounted) return;
        setState(() {
          _nameExists = true;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User exists, enter a different name')),
        );
        return;
      }

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
