// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:quizzard_thesis/screens/menu/custom_config.dart';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import '../profile/edit_profile_form.dart';

import 'add_csv.dart';
import 'add_cutscene_csv.dart';
import 'download_csv.dart';
import 'reset_config.dart';

class MenuScreen extends StatelessWidget {
  final bool hideSubjects;
  final bool hideLogout;
  final bool hideProgress; // new flag
  final int? adminProfileId;
  const MenuScreen({
    super.key,
    this.hideSubjects = false,
    this.hideLogout = false,
    this.hideProgress = false,
    this.adminProfileId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download CSV templates'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DownloadCsvScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Upload Questions CSV'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddCsvScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Upload Cutscenes CSV'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddCutsceneCsvScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('Manage Questions'),
            onTap: () => Navigator.of(context).pushNamed('/questions'),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Custom Configurations'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomConfigScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('Reset Configurations'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ResetConfigScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Reset Admin Passcode'),
            onTap: () async {
              if (adminProfileId == null) {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Not available'),
                    content: const Text(
                      'Reset passcode is only available for admin users.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              final TextEditingController newCtrl = TextEditingController();
              final TextEditingController confCtrl = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Reset MPIN'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: newCtrl,
                        decoration: const InputDecoration(
                          labelText: 'New 4-digit MPIN',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                      ),
                      TextField(
                        controller: confCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Confirm MPIN',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final a = newCtrl.text.trim();
                        final b = confCtrl.text.trim();
                        if (a.length != 4 || a != b) return;
                        Navigator.of(c).pop(true);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (ok == true) {
                final repo = UserRepository();
                final users = await repo.getAll();
                final admin = users.firstWhere(
                  (u) => u.profileID == adminProfileId,
                  orElse: () => User(profileID: adminProfileId, name: 'Admin'),
                );
                final hashed = sha256
                    .convert(utf8.encode(newCtrl.text.trim()))
                    .toString();
                final updated = User(
                  profileID: admin.profileID,
                  name: admin.name,
                  avatar: admin.avatar,
                  isAdmin: true,
                  adminPasscode: hashed,
                );
                await repo.update(updated);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Passcode reset')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Delete Learner Account'),
            onTap: () async {
              // show list of non-admin accounts to delete
              final repo = UserRepository();
              final users = await repo.getAll();
              final nonAdmins = users.where((u) => u.isAdmin != true).toList();
              await showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete account'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: nonAdmins.isEmpty
                        ? const Text('No non-admin accounts available')
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: nonAdmins.length,
                            itemBuilder: (ctx, i) {
                              final u = nonAdmins[i];
                              return ListTile(
                                title: Text(u.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: ctx,
                                      builder: (cc) => AlertDialog(
                                        title: const Text('Confirm delete'),
                                        content: Text(
                                          'Delete account "${u.name}"?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(cc).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(cc).pop(true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await repo.delete(u.profileID!);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Account deleted'),
                                          ),
                                        );
                                        Navigator.of(context).pop();
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Admin Profile'),
            onTap: () async {
              if (adminProfileId == null) return;
              final edited = await showDialog<bool>(
                context: context,
                builder: (c) => EditProfileForm(profileId: adminProfileId!),
              );
              if (edited == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin profile updated')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Delete Admin Profile'),
            onTap: () async {
              if (adminProfileId == null) {
                showDialog(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Not available'),
                    content: const Text(
                      'No admin profile available to delete.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              final repo = UserRepository();
              final users = await repo.getAll();
              final admin = users.firstWhere(
                (u) => u.profileID == adminProfileId,
                orElse: () => User(profileID: adminProfileId, name: ''),
              );

              final mpinCtrl = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Confirm Delete Admin'),
                  content: TextField(
                    controller: mpinCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Enter admin MPIN to confirm',
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(c).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(c).pop(true),
                      child: const Text('Confirm'),
                    ),
                  ],
                ),
              );

              if (ok != true) return;
              final entered = mpinCtrl.text.trim();
              if (entered.length != 4) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Invalid MPIN')));
                }
                return;
              }
              final hashed = sha256.convert(utf8.encode(entered)).toString();
              if (admin.adminPasscode == null ||
                  admin.adminPasscode != hashed) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Invalid MPIN')));
                }
                return;
              }

              // confirmed, delete admin
              await repo.delete(admin.profileID!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin account deleted')),
                );
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (r) => false);
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (r) => false),
          ),
        ],
      ),
    );
  }
}
