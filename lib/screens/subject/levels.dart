import 'package:flutter/material.dart';
import '../../repositories/progress_repository.dart';
import 'game_content.dart';

class LevelsScreen extends StatefulWidget {
  final int subjID;
  final String difficulty;
  final String subjName;
  final int profileId;
  const LevelsScreen({
    super.key,
    required this.subjID,
    required this.difficulty,
    required this.subjName,
    required this.profileId,
  });

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> with RouteAware {
  final _progressRepo = ProgressRepository();
  late Future<void> _future;
  int _maxCompletedLevel = 0; // highest completed level (1..5), 0 = none

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    // load progress for this profile/subj/difficulty and compute completed levels
    final all = await _progressRepo.getByProfile(widget.profileId);
    final completedLevels = <int>{};
    for (final p in all) {
      if (p.subjID == widget.subjID &&
          p.difficulty == widget.difficulty &&
          p.progressLevel == 'completed' &&
          (p.level != null)) {
        completedLevels.add(p.level!);
      }
    }
    if (completedLevels.isNotEmpty) {
      _maxCompletedLevel = completedLevels.reduce((a, b) => a > b ? a : b);
    } else {
      _maxCompletedLevel = 0;
    }
  }

  bool _isLevelUnlocked(int level) {
    if (level == 1) {
      return true;
    }
    if (level == 99) {
      // boss unlocked only after level 5 completed
      return _maxCompletedLevel >= 5;
    }
    return _maxCompletedLevel >= (level - 1);
  }

  @override
  Widget build(BuildContext context) {
    final levels = List<int>.generate(5, (i) => i + 1);
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.subjName} - ${widget.difficulty}'),
          ),
          body: ListView(
            children: [
              ...levels.map((lvl) {
                final unlocked = _isLevelUnlocked(lvl);
                return ListTile(
                  title: Text('Level $lvl'),
                  subtitle: Text(unlocked ? 'Unlocked' : 'Locked'),
                  enabled: unlocked,
                  onTap: unlocked
                      ? () async {
                          // await the level route and refresh progress when user returns
                          await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => GameContent(
                                subjID: widget.subjID,
                                subjName: widget.subjName,
                                difficulty: widget.difficulty,
                                level: lvl,
                                profileId: widget.profileId,
                              ),
                            ),
                          );
                          // reload progress and rebuild UI
                          setState(() {
                            _future = _load();
                          });
                        }
                      : null,
                );
              }),
              const Divider(),
              Builder(
                builder: (ctx) {
                  final bossUnlocked = _isLevelUnlocked(99);
                  return ListTile(
                    title: const Text('Final Boss'),
                    subtitle: Text(
                      bossUnlocked
                          ? 'Unlocked'
                          : 'Locked (complete level 5 to unlock)',
                    ),
                    enabled: bossUnlocked,
                    onTap: bossUnlocked
                        ? () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => GameContent(
                                  subjID: widget.subjID,
                                  subjName: widget.subjName,
                                  difficulty: widget.difficulty,
                                  level: 99,
                                  profileId: widget.profileId,
                                ),
                              ),
                            );
                            setState(() {
                              _future = _load();
                            });
                          }
                        : null,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
