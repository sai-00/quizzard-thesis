import 'package:flutter/material.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/game_repository.dart';
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
  Map<int, int> _bestPoints =
      {}; // best points per level for this subj/difficulty
  Map<int, int> _questionCounts =
      {}; // number of questions available per level (may be < defaults)

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<void> _load() async {
    // load progress for this profile/subj/difficulty and compute completed levels
    final all = await _progressRepo.getByProfile(widget.profileId);
    final completedLevels = <int>{};
    _bestPoints = {};
    _questionCounts = {};

    for (final p in all) {
      if (p.subjID == widget.subjID &&
          p.difficulty == widget.difficulty &&
          (p.level != null)) {
        final lvl = p.level!;
        if (p.progressLevel == 'completed') {
          completedLevels.add(lvl);
          final pts = p.points;
          final prev = _bestPoints[lvl] ?? 0;
          if (pts > prev) {
            _bestPoints[lvl] = pts;
          }
        }
      }
    }

    // determine how many questions each level actually has (may be less than defaults)
    final gameRepo = GameRepository();
    final levelsToQuery = [1, 2, 3, 4, 5, 99];
    for (final lvl in levelsToQuery) {
      try {
        final q = await gameRepo.loadQuestions(
          subjID: widget.subjID,
          difficulty: widget.difficulty,
          level: lvl,
          isBoss: lvl == 99,
        );
        _questionCounts[lvl] = q.length;
      } catch (e) {
        // fallback to defaults if something goes wrong
        _questionCounts[lvl] = lvl == 99 ? 10 : 5;
      }
    }

    if (completedLevels.isNotEmpty) {
      _maxCompletedLevel = completedLevels.reduce((a, b) => a > b ? a : b);
    } else {
      _maxCompletedLevel = 0;
    }

    if (mounted) setState(() {});
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

  /// Compute star rating for a level based on best points recorded.
  /// Normal levels: 5 questions; boss: 10 questions.
  int _starsForLevel(int level) {
    final pts = _bestPoints[level] ?? 0;
    final total = _questionCounts[level] ?? (level == 99 ? 10 : 5);
    if (total <= 0 || pts <= 0) return 0;

    if (level == 99) {
      final one = (total * 0.7).ceil(); // ~70%
      final two = (total * 0.8).ceil(); // ~80%
      final three = total; // perfect
      if (pts >= three) return 3;
      if (pts >= two) return 2;
      if (pts >= one) return 1;
      return 0;
    } else {
      final one = (total * 3 / 5).ceil(); // 60%
      final two = (total * 4 / 5).ceil(); // 80%
      final three = total; // perfect
      if (pts >= three) return 3;
      if (pts >= two) return 2;
      if (pts >= one) return 1;
      return 0;
    }
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Level $lvl',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: unlocked
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    unlocked ? 'Unlocked' : 'Locked',
                                    textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: unlocked
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (i) {
                                final stars = _starsForLevel(lvl);
                                final filledColor = unlocked
                                    ? Colors.amber
                                    : Colors.white70;
                                final hsl = HSLColor.fromColor(color);
                                final emptyColor = hsl
                                    .withLightness(
                                      (hsl.lightness - 0.18).clamp(0.0, 1.0),
                                    )
                                    .toColor();
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: i < stars ? filledColor : emptyColor,
                                    size: 35,
                                  ),
                                );
                              }),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Final Level',
                                      textAlign: TextAlign.left,
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
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        color: bossUnlocked
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(3, (i) {
                                  final stars = _starsForLevel(99);
                                  final filledColor = bossUnlocked
                                      ? Colors.amber
                                      : Colors.white70;
                                  final hsl = HSLColor.fromColor(
                                    bossUnlocked
                                        ? Colors.red
                                        : Colors.grey.shade700,
                                  );
                                  final emptyColor = hsl
                                      .withLightness(
                                        (hsl.lightness - 0.18).clamp(0.0, 1.0),
                                      )
                                      .toColor();
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Icon(
                                      Icons.star,
                                      color: i < stars
                                          ? filledColor
                                          : emptyColor,
                                      size: 35,
                                    ),
                                  );
                                }),
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
