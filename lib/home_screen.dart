import 'package:flutter/material.dart';
import 'screens/subject/subject_list.dart';
import 'screens/progress/progress_tracker_list.dart';
import 'screens/profile/edit_profile_form.dart';
import 'repositories/user_repository.dart';
import 'models/user.dart';

class HomeScreen extends StatefulWidget {
  final int profileId;
  const HomeScreen({super.key, required this.profileId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0; // 0 = subjects, 1 = progress
  String _profileName = '';
  final _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfileName());
  }

  Future<void> _loadProfileName() async {
    try {
      final users = await _userRepo.getAll();
      final user = users.firstWhere(
        (u) => u.profileID == widget.profileId,
        orElse: () => User(
          profileID: widget.profileId,
          name: 'Profile ${widget.profileId}',
        ),
      );
      if (!mounted) return;
      // user.name is non-nullable; no null-aware fallback needed (orElse provides a default)
      setState(() => _profileName = user.name);
    } catch (e) {
      if (!mounted) return;
      setState(() => _profileName = 'Profile ${widget.profileId}');
    }
  }

  void _logout() {
    // remove everything and go back to profile selection
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body = _index == 0
        ? SubjectList(profileId: widget.profileId)
        : ProgressTrackerList(profileId: widget.profileId);

    final title = _profileName.isNotEmpty
        ? 'Home - $_profileName'
        : 'Home - Profile ${widget.profileId}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              // open edit profile form
              final edited = await showDialog<bool>(
                context: context,
                builder: (_) => EditProfileForm(profileId: widget.profileId),
              );
              if (edited == true) {
                _loadProfileName();
              }
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Subjects'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
