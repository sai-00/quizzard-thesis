import 'package:flutter/material.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/question_repository.dart';

class ProgressTrackerList extends StatefulWidget {
  final int profileId;
  const ProgressTrackerList({super.key, required this.profileId});

  @override
  State<ProgressTrackerList> createState() => _ProgressTrackerListState();
}

class _ProgressTrackerListState extends State<ProgressTrackerList> {
  final _progressRepo = ProgressRepository();
  final _questionRepo = QuestionRepository();
  late Future<void> _future;

  // aggregated data structures
  Map<int, String> _subjectNames = {};
  Map<int, Map<String, int>> _pointsPerSubject =
      {}; // subjID -> {difficulty: points}
  Map<int, String> _currentDifficulty = {}; // subjID -> difficulty

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    final subjects = await _questionRepo
        .getSubjects(); // expected: [{subjID: n, subjName: '...'}, ...]
    _subjectNames = {
      for (final s in subjects) s['subjID'] as int: s['subjName'] as String,
    };

    final rows = await _progressRepo.getByProfile(widget.profileId);
    // init maps
    _pointsPerSubject = {};
    _currentDifficulty = {};

    for (final r in rows) {
      _pointsPerSubject.putIfAbsent(
        r.subjID,
        () => {'Easy': 0, 'Medium': 0, 'Hard': 0},
      );
      final diff = r.difficulty ?? 'Easy';
      _pointsPerSubject[r.subjID]![diff] =
          (_pointsPerSubject[r.subjID]![diff] ?? 0) + (r.points);
      // track last played difficulty as current
      _currentDifficulty[r.subjID] =
          r.difficulty ?? _currentDifficulty[r.subjID] ?? 'Easy';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final subjIds = _subjectNames.keys.toList();
        if (subjIds.isEmpty) {
          return const Center(child: Text('No subjects found'));
        }
        return ListView.builder(
          itemCount: subjIds.length,
          itemBuilder: (context, i) {
            final sid = subjIds[i];
            final name = _subjectNames[sid] ?? 'Subject $sid';
            final points =
                _pointsPerSubject[sid] ?? {'Easy': 0, 'Medium': 0, 'Hard': 0};
            final current = _currentDifficulty[sid] ?? 'Easy';
            return Card(
              child: ListTile(
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current difficulty: $current'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _badge('Easy', points['Easy'] ?? 0, Colors.green),
                        const SizedBox(width: 8),
                        _badge('Medium', points['Medium'] ?? 0, Colors.orange),
                        const SizedBox(width: 8),
                        _badge('Hard', points['Hard'] ?? 0, Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _badge(String label, int pts, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha((0.12 * 255).round()),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Text(label),
        const SizedBox(width: 6),
        Text(pts.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}
