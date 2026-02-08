import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../repositories/user_repository.dart';

class AddAdminProfileForm extends StatefulWidget {
  const AddAdminProfileForm({super.key});

  @override
  State<AddAdminProfileForm> createState() => _AddAdminProfileFormState();
}

class _AddAdminProfileFormState extends State<AddAdminProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    setState(() => _working = true);
    try {
      // store hashed MPIN
      final hashed = sha256.convert(utf8.encode(pass)).toString();
      final user = User(name: name, isAdmin: true, adminPasscode: hashed);
      await UserRepository().add(user);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _working = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to create admin: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Admin Account'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            TextFormField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: '4-digit MPIN'),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter passcode';
                final t = v.trim();
                if (t.length != 4) return 'Passcode must be 4 digits';
                if (!RegExp(r'^\d{4}$').hasMatch(t)) {
                  return 'Passcode must be numeric';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(labelText: 'Confirm MPIN'),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Confirm passcode';
                final t = v.trim();
                if (t != _passCtrl.text.trim()) return 'Passcodes do not match';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _working ? null : _submit,
          child: _working
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
