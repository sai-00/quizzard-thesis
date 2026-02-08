import 'dart:io';

import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../repositories/user_repository.dart';
import 'edit_profile_form.dart';

class ProfileCard extends StatelessWidget {
  final User user;
  final void Function(User)? onTap;
  final VoidCallback? onDeleted;
  final VoidCallback? onEdited;
  const ProfileCard({
    super.key,
    required this.user,
    this.onTap,
    this.onDeleted,
    this.onEdited,
  });

  @override
  Widget build(BuildContext context) {
    // Profile tile with name below and delete icon under the name.
    return InkWell(
      onTap: onTap == null ? null : () => onTap!(user),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo placeholder (show avatar if available)
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(120),
            ),
            child: (user.avatar != null && user.avatar!.isNotEmpty)
                ? Builder(
                    builder: (context) {
                      try {
                        final val = user.avatar!;
                        // asset-based avatar
                        if (val.startsWith('assets/')) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(120),
                            child: Image.asset(
                              val,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          );
                        }

                        final f = File(val);
                        if (f.existsSync()) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(120),
                            child: Image.file(
                              f,
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          );
                        }
                      } catch (_) {}
                      // fallback to initial letter
                      return Center(
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          // edit and delete icons below the name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: (user.profileID == null || user.isAdmin == true)
                    ? null
                    : () async {
                        final edited = await showDialog<bool>(
                          context: context,
                          builder: (c) =>
                              EditProfileForm(profileId: user.profileID!),
                        );
                        if (edited == true) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile updated')),
                            );
                          }
                          onEdited?.call();
                        }
                      },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: (user.isAdmin == true)
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete profile'),
                            content: Text(
                              'Delete profile "${user.name}"? This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(c).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(c).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await UserRepository().delete(user.profileID!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Profile deleted')),
                            );
                          }
                          onDeleted?.call();
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
