import 'package:flutter/material.dart';
import '../../repositories/progress_repository.dart';
import '../subject/levels.dart';
import '../../navigation/route_observer.dart';

class SubjectContent extends StatelessWidget {
  final int subjID;
  final String subjName;
  final int profileId;
  const SubjectContent({
    super.key,
    required this.subjID,
    required this.subjName,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subjName)),
      body: DifficultyChooser(
        subjID: subjID,
        subjName: subjName,
        profileId: profileId,
      ),
    );
  }
}

class DifficultyChooser extends StatefulWidget {
  final int subjID;
  final String subjName;
  final int profileId;
  const DifficultyChooser({
    super.key,
    required this.subjID,
    required this.subjName,
    required this.profileId,
  });

  @override
  State<DifficultyChooser> createState() => _DifficultyChooserState();
}

class _DifficultyChooserState extends State<DifficultyChooser> with RouteAware {
  final _progressRepo = ProgressRepository();
  bool _loading = true;
  // track completed levels per difficulty (set of level numbers completed)
  final Map<String, Set<int>> _completed = {
    'Easy': {},
    'Medium': {},
    'Hard': {},
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // called when a route above this one was popped and this route is visible again
  @override
  void didPopNext() {
    _reload();
  }

  // also refresh when pushed (optional)
  @override
  void didPush() {
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    await _load();
  }

  Future<void> _load() async {
    _completed['Easy'] = {};
    _completed['Medium'] = {};
    _completed['Hard'] = {};
    final rows = await _progressRepo.getByProfile(widget.profileId);
    for (final r in rows) {
      if (r.subjID != widget.subjID) continue;
      final diff = (r.difficulty ?? 'Easy');
      if (r.progressLevel == 'completed' && r.level != null) {
        _completed.putIfAbsent(diff, () => <int>{}).add(r.level!);
      }
      // include boss (99) as completed if present
      if (r.progressLevel == 'completed' && r.level == 99) {
        _completed.putIfAbsent(diff, () => <int>{}).add(99);
      }
    }
    setState(() => _loading = false);
  }

  bool _hasAllLevelsAndBoss(String diff) {
    final set = _completed[diff] ?? {};
    for (final lvl in [1, 2, 3, 4, 5, 99]) {
      if (!set.contains(lvl)) return false;
    }
    return true;
  }

  bool _isDifficultyUnlocked(String diff) {
    if (diff == 'Easy') return true;
    if (diff == 'Medium') return _hasAllLevelsAndBoss('Easy');
    if (diff == 'Hard') return _hasAllLevelsAndBoss('Medium');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final items = ['Easy', 'Medium', 'Hard'];
    return ListView(
      padding: const EdgeInsets.all(8),
      children: items.map((d) {
        final unlocked = _isDifficultyUnlocked(d);
        return Card(
          child: ListTile(
            title: Text(d),
            subtitle: Text(
              unlocked
                  ? 'Tap to start $d levels'
                  : 'Locked — complete all levels (1–5) and final boss of previous difficulty',
            ),
            trailing: unlocked
                ? const Icon(Icons.chevron_right)
                : const Icon(Icons.lock),
            enabled: unlocked,
            onTap: unlocked
                ? () async {
                    // await the Levels screen and reload when the user returns
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => LevelsScreen(
                          subjID: widget.subjID,
                          difficulty: d,
                          subjName: widget.subjName,
                          profileId: widget.profileId,
                        ),
                      ),
                    );
                    await _reload();
                  }
                : null,
          ),
        );
      }).toList(),
    );
  }
}
