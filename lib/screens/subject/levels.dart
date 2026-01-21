import 'package:flutter/material.dart';
import '../../repositories/progress_repository.dart';
import '../game_loop/game_view.dart';

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
        // Render levels as cards similar to subject cards, with subject-specific colors.
        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.subjName} - ${widget.difficulty}'),
          ),
          body: ListView(
            children: [
              ...levels.map((lvl) {
                final unlocked = _isLevelUnlocked(lvl);
                final baseColor = _levelColor(widget.subjName.toLowerCase());
                final color = unlocked ? baseColor : Colors.grey.shade700;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10.0,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: unlocked
                          ? () async {
                              await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => GameView(
                                    subjID: widget.subjID,
                                    subject: widget.subjName,
                                    difficulty: widget.difficulty,
                                    level: lvl,
                                    isBossLevel: false,
                                    profileID: widget.profileId,
                                  ),
                                ),
                              );
                              setState(() {
                                _future = _load();
                              });
                            }
                          : null,
                      child: Container(
                        color: color,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Level $lvl',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: unlocked ? Colors.white : Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              unlocked ? 'Unlocked' : 'Locked',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: unlocked ? Colors.white : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const Divider(),
              Builder(
                builder: (ctx) {
                  final bossUnlocked = _isLevelUnlocked(99);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 10.0,
                    ),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onTap: bossUnlocked
                            ? () async {
                                await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => GameView(
                                      subjID: widget.subjID,
                                      subject: widget.subjName,
                                      difficulty: widget.difficulty,
                                      level: 99,
                                      isBossLevel: true,
                                      profileID: widget.profileId,
                                    ),
                                  ),
                                );
                                setState(() {
                                  _future = _load();
                                });
                              }
                            : null,
                        child: Container(
                          color: bossUnlocked
                              ? Colors.red
                              : Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18.0,
                            vertical: 20.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Final Boss',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: bossUnlocked
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bossUnlocked
                                    ? 'Unlocked'
                                    : 'Locked (complete level 5 to unlock)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: bossUnlocked
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _levelColor(String subj) {
    switch (subj) {
      case 'math':
        return const Color.fromARGB(255, 16, 48, 53);
      case 'reading':
      case 'eng':
        return const Color.fromARGB(255, 37, 13, 53);
      case 'science':
      case 'sci':
        return const Color.fromARGB(255, 46, 10, 10);
      default:
        return Colors.grey.shade800;
    }
  }
}
