import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'profile_list.dart';
import 'add_profile_form.dart';
import 'add_admin_profile_form.dart';
import '../../repositories/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // use the now-public state type
  final GlobalKey<ProfileListState> _listKey = GlobalKey<ProfileListState>();
  int _profileCount = 0;
  bool _adminExists = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAdminExists());
  }

  Future<void> _checkAdminExists() async {
    try {
      final users = await UserRepository().getAll();
      final has = users.any((u) => u.isAdmin == true);
      if (!mounted) return;
      setState(() => _adminExists = has);
    } catch (e) {
      // ignore and remain false
    }
  }

  void _onProfileSelected(User user) {
    if (user.isAdmin == true) {
      // require MPIN login before entering admin (compare hashed values)
      showDialog<bool>(
        context: context,
        builder: (c) {
          final mpinCtrl = TextEditingController();
          return AlertDialog(
            title: const Text('Admin Login'),
            content: TextField(
              controller: mpinCtrl,
              decoration: const InputDecoration(
                labelText: 'Enter 4-digit MPIN',
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final entered = mpinCtrl.text.trim();
                  if (entered.isEmpty) return; // simple guard
                  // hash entered and compare
                  try {
                    final hashed = _hashMpin(entered);
                    if (user.adminPasscode != null &&
                        hashed == user.adminPasscode) {
                      Navigator.of(c).pop(true);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid MPIN')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid MPIN')),
                    );
                  }
                },
                child: const Text('Login'),
              ),
            ],
          );
        },
      ).then((ok) {
        if (ok == true && mounted) {
          Navigator.of(
            context,
          ).pushReplacementNamed('/admin', arguments: user.profileID);
        }
      });
    } else {
      Navigator.of(
        context,
      ).pushReplacementNamed('/home', arguments: user.profileID);
    }
  }

  String _hashMpin(String mpin) {
    return sha256.convert(utf8.encode(mpin)).toString();
  }

  Future<void> _openAddProfileForm() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const AddProfileForm(),
    );

    if (added == true && mounted) {
      _listKey.currentState?.refresh();
    }
  }

  Future<void> _openAddAdminForm() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const AddAdminProfileForm(),
    );

    if (added == true && mounted) {
      _listKey.currentState?.refresh();
      setState(() => _adminExists = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Profile – $_profileCount Profiles'),
        actions: [
          if (!_adminExists)
            IconButton(
              onPressed: _openAddAdminForm,
              icon: const Icon(Icons.admin_panel_settings),
            ),
        ],
      ),
      body: ProfileList(
        key: _listKey,
        onTap: _onProfileSelected,
        onAdd: _openAddProfileForm,
        onCountChanged: (count) => setState(() => _profileCount = count),
      ),
    );
  }
}
