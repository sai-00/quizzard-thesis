import 'package:flutter/material.dart';
import 'admin_progress.dart';
import '../menu/menu_screen.dart';

class AdminScreen extends StatefulWidget {
  final int? profileId;
  const AdminScreen({super.key, this.profileId});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _index = 0; // 0 = progress, 1 = settings

  void _logout() {
    // remove everything and go back to profile selection
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _index == 0
        ? const AdminProgress()
        : MenuScreen(adminProfileId: widget.profileId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
