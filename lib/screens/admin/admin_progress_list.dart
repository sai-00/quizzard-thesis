import 'package:flutter/material.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/question_repository.dart';
// models are used indirectly via repositories
import 'admin_progress_card.dart';

class AdminProgressList extends StatefulWidget {
  const AdminProgressList({super.key});

  @override
  State<AdminProgressList> createState() => _AdminProgressListState();
}

class _AdminProgressListState extends State<AdminProgressList> {
  final _userRepo = UserRepository();
  final _progressRepo = ProgressRepository();
  final _questionRepo = QuestionRepository();
  late Future<List<Widget>> _future;

  @override
  void initState() {
    super.initState();
    _future = _buildCards();
  }

  Future<List<Widget>> _buildCards() async {
    final users = await _userRepo.getAll();
    final subjects = await _questionRepo.getSubjects();
    final subjectNames = <int, String>{
      for (final s in subjects) s['subjID'] as int: s['subjName'] as String,
    };

    final nonAdminUsers = users.where((u) => u.isAdmin != true).toList();
    final cards = <Widget>[];

    for (final u in nonAdminUsers) {
      final rows = await _progressRepo.getByProfile(u.profileID!);
      // latest runID from most recent row
      String? latestRun;
      String? latestDate;
      int latestSessionPoints = 0;

      if (rows.isNotEmpty) {
        latestRun = rows.first.runID ?? rows.first.datePlayed;
        latestDate = rows.first.datePlayed ?? rows.first.timeOn;
        // sum points for the latest run
        final runId = latestRun;
        if (runId != null) {
          final runRows = rows.where((r) => (r.runID ?? r.datePlayed) == runId);
          latestSessionPoints = runRows.fold<int>(0, (p, e) => p + (e.points));
          // prefer datePlayed from first runRows if available
          final first = runRows.firstWhere(
            (_) => true,
            orElse: () => rows.first,
          );
          latestDate = first.datePlayed ?? first.timeOn;
        }
      }

      // cumulative per subject/difficulty across all rows
      final Map<int, Map<String, int>> subjDiff = {};
      for (final r in rows) {
        subjDiff.putIfAbsent(
          r.subjID,
          () => {'Easy': 0, 'Medium': 0, 'Hard': 0},
        );
        final diff = r.difficulty ?? 'Easy';
        subjDiff[r.subjID]![diff] = (subjDiff[r.subjID]![diff] ?? 0) + r.points;
      }

      cards.add(
        AdminProgressCard(
          user: u,
          latestDate: latestDate,
          latestSessionPoints: latestSessionPoints,
          subjDifficultyPoints: subjDiff,
          subjectNames: subjectNames,
        ),
      );
    }

    return cards;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _buildCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Widget>>(
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
                const Text('Failed to load admin progress'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(snap.error.toString()),
                ),
              ],
            ),
          );
        }

        final cards = snap.data ?? [];
        if (cards.isEmpty) {
          return const Center(child: Text('No learner progress found'));
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (c, i) => cards[i],
          ),
        );
      },
    );
  }
}
