import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../repositories/user_repository.dart';

class ProfileCard extends StatelessWidget {
  final User user;
  final void Function(User)? onTap;
  final VoidCallback? onDeleted;
  const ProfileCard({
    super.key,
    required this.user,
    this.onTap,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
      ),
      title: Text(user.name),
      onTap: onTap == null ? null : () => onTap!(user),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Profile deleted')));
            }
            // notify parent to refresh list
            onDeleted?.call();
          }
        },
      ),
    );
  }
}
