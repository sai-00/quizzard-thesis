import 'package:flutter/material.dart';
import '../subject/subject_list.dart';
import '../progress/progress_tracker_list.dart';
import 'add_csv.dart';

class MenuScreen extends StatelessWidget {
  final bool hideSubjects;
  final bool hideLogout;
  final bool hideProgress; // new flag
  const MenuScreen({
    super.key,
    this.hideSubjects = false,
    this.hideLogout = false,
    this.hideProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        children: [
          if (!hideSubjects)
            ListTile(
              leading: const Icon(Icons.book),
              title: const Text('Subjects'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SubjectList(profileId: 1),
                ),
              ),
            ),
          if (!hideProgress)
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Progress Tracker'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProgressTrackerList(profileId: 1),
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Download CSV templates'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddCsvScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Add Questions CSV'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddCsvScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Add Cutscenes CSV'),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddCsvScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('Manage Questions'),
            onTap: () => Navigator.of(context).pushNamed('/questions'),
          ),
          if (!hideLogout)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
        ],
      ),
    );
  }
}
