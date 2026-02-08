import 'package:flutter/material.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/question_repository.dart';
import 'progress_tracker_card.dart';

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

    // Build cumulative per-subject difficulty totals and session grouping
    final Map<int, Map<String, int>> totals = {};
    final Map<int, Map<String, List<Map<String, dynamic>>>> sessionsBySubj = {};

    for (final r in rows) {
      totals.putIfAbsent(r.subjID, () => {'Easy': 0, 'Medium': 0, 'Hard': 0});
      final diff = r.difficulty ?? 'Easy';
      totals[r.subjID]![diff] = (totals[r.subjID]![diff] ?? 0) + r.points;

      // group by runID (fallback to datePlayed)
      final runKey =
          r.runID ?? r.datePlayed ?? DateTime.now().toIso8601String();
      sessionsBySubj.putIfAbsent(r.subjID, () => {});
      sessionsBySubj[r.subjID]!.putIfAbsent(runKey, () => []);
      sessionsBySubj[r.subjID]![runKey]!.add({
        'datePlayed': r.datePlayed,
        'points': r.points,
        'runID': runKey,
      });

      // track last played difficulty as current (most recent wins because rows ordered by date desc)
      _currentDifficulty[r.subjID] =
          r.difficulty ?? _currentDifficulty[r.subjID] ?? 'Easy';
    }

    // convert sessionsBySubj into list of recent sessions with summed points
    _pointsPerSubject = totals;
    // replace current difficulty is already set

    // store a map of subjID -> List of sessions (datePlayed, points), latest first
    final Map<int, List<Map<String, dynamic>>> recentSessions = {};
    sessionsBySubj.forEach((subjID, runMap) {
      final runs = <Map<String, dynamic>>[];
      for (final entry in runMap.entries) {
        final list = entry.value;
        final pts = list.fold<int>(0, (p, e) => p + (e['points'] as int? ?? 0));
        final firstDate = list.first['datePlayed'] as String?;
        runs.add({'datePlayed': firstDate, 'points': pts, 'runID': entry.key});
      }
      runs.sort((a, b) {
        final da =
            DateTime.tryParse(a['datePlayed'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db =
            DateTime.tryParse(b['datePlayed'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
      recentSessions[subjID] = runs;
    });

    // attach recent sessions to a field used by the UI via a temporary variable stored on the state
    _recentSessionsStore = recentSessions;
  }

  late Map<int, List<Map<String, dynamic>>> _recentSessionsStore;

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
            final sessions = _recentSessionsStore[sid] ?? [];
            return ProgressTrackerCard(
              subjectName: name,
              difficultyPoints: points,
              sessions: sessions,
            );
          },
        );
      },
    );
  }

  // badges are rendered by ProgressTrackerCard
}
