import 'package:flutter/material.dart';
import '../../models/user.dart';
import 'profile_list.dart';
import '../menu/menu_screen.dart';
import 'add_profile_form.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // use the now-public state type
  final GlobalKey<ProfileListState> _listKey = GlobalKey<ProfileListState>();

  void _onProfileSelected(User user) {
    Navigator.of(
      context,
    ).pushReplacementNamed('/home', arguments: user.profileID);
  }

  void _openMenu() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MenuScreen(
          hideSubjects: true,
          hideProgress: true,
          hideLogout: true,
        ),
      ),
    );
  }

  Future<void> _openAddProfileForm() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => const AddProfileForm(),
    );

    // ✅ if a new profile was added, refresh the list
    if (added == true && mounted) {
      _listKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile'),
        actions: [
          IconButton(onPressed: _openMenu, icon: const Icon(Icons.menu)),
        ],
      ),
      body: ProfileList(key: _listKey, onTap: _onProfileSelected),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddProfileForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}
