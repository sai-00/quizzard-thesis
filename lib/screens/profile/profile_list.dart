import 'package:flutter/material.dart';
import '../../repositories/user_repository.dart';
import '../../models/user.dart';
import 'profile_card.dart';

typedef OnProfileTap = void Function(User user);

class ProfileList extends StatefulWidget {
  final OnProfileTap? onTap;
  const ProfileList({super.key, this.onTap});

  @override
  // return the public state type
  ProfileListState createState() => ProfileListState();
}

// Made public (no leading underscore)
class ProfileListState extends State<ProfileList> {
  final repo = UserRepository();
  late Future<List<User>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = repo.getAll();
  }

  /// ✅ Public method so parent (ProfileScreen) can trigger a refresh
  Future<void> refresh() async {
    setState(() {
      _load();
    });
  }

  Future<void> _onDeleted() async {
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<User>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load profiles'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: refresh, child: const Text('Retry')),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    snap.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }
        final users = snap.data ?? [];
        if (users.isEmpty) return const Center(child: Text('No profiles yet'));
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) => ProfileCard(
            user: users[i],
            onTap: widget.onTap,
            onDeleted: _onDeleted,
          ),
        );
      },
    );
  }
}
