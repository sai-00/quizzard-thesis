import 'package:flutter/material.dart';
import '../../repositories/user_repository.dart';
import '../../models/user.dart';
import 'profile_card.dart';

typedef OnProfileTap = void Function(User user);

class ProfileList extends StatefulWidget {
  final OnProfileTap? onTap;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onCountChanged;
  const ProfileList({super.key, this.onTap, this.onAdd, this.onCountChanged});

  @override
  // return the public state type
  ProfileListState createState() => ProfileListState();
}

// Made public (no leading underscore)
class ProfileListState extends State<ProfileList> {
  final repo = UserRepository();
  late Future<List<User>> _future;
  List<User>? _latestUsers;

  /// Synchronous access to current profile count (frontend only)
  int get profileCount => _latestUsers?.length ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = repo.getAll();
  }

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
        final users = List<User>.from(snap.data ?? []);
        // Ensure admin accounts appear first in the list
        users.sort((a, b) {
          if (a.isAdmin == b.isAdmin) {
            return (a.profileID ?? 0).compareTo(b.profileID ?? 0);
          }
          return a.isAdmin == true ? -1 : 1;
        });
        _latestUsers = users;
        // notify parent of current count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onCountChanged?.call(users.length);
        });
        // Always show an inline "Add Profile" tile as the last item.
        final total = users.length + 1;

        // Center grid with max 2 columns
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: total,
              itemBuilder: (context, i) {
                if (i == users.length) {
                  // Add tile; disable when max reached
                  final bool limitReached = users.length >= 35;
                  return InkWell(
                    onTap: limitReached ? null : widget.onAdd,
                    child: Opacity(
                      opacity: limitReached ? 0.5 : 1.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: limitReached
                                  ? Colors.grey[300]
                                  : const Color.fromARGB(255, 118, 70, 190),
                              borderRadius: BorderRadius.circular(120),
                              border: Border.all(
                                color: limitReached
                                    ? Colors.grey
                                    : const Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: 48,
                                color: limitReached
                                    ? Colors.grey
                                    : const Color.fromARGB(137, 255, 255, 255),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            limitReached ? 'Limit reached' : 'Add Profile',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final user = users[i];
                return ProfileCard(
                  user: user,
                  onTap: widget.onTap,
                  onDeleted: _onDeleted,
                  onEdited: _onDeleted,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
