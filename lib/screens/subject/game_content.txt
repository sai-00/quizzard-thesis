import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../repositories/question_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../models/progress.dart';

class GameContent extends StatefulWidget {
  final int subjID;
  final String subjName;
  final String difficulty;
  final int level; // 1..5 or 99 for boss
  final int profileId;
  const GameContent({
    super.key,
    required this.subjID,
    required this.subjName,
    required this.difficulty,
    required this.level,
    required this.profileId,
  });

  @override
  State<GameContent> createState() => _GameContentState();
}

class _GameContentState extends State<GameContent> {
  final _qRepo = QuestionRepository();
  final _pRepo = ProgressRepository();
  late List<Question> _questions = [];
  int _index = 0;
  bool _loading = true;
  final Random _rnd = Random();

  // run identifier to group answers for a single level attempt
  late final String _runId;

  // answer state for current question
  bool _answered = false;
  String? _selectedAnswer;
  bool _lastCorrect = false;

  @override
  void initState() {
    super.initState();
    _runId = DateTime.now().toIso8601String();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final all = await _qRepo.getBySubject(
      widget.subjID,
      difficulty: widget.difficulty,
    );
    all.shuffle(_rnd);
    int perLevel = 5;
    List<Question> selected;
    if (widget.level == 99) {
      selected = all.take(min(10, all.length)).toList();
    } else {
      final start = (widget.level - 1) * perLevel;
      if (start >= all.length) {
        selected = all.take(min(perLevel, all.length)).toList();
      } else {
        selected = all.skip(start).take(perLevel).toList();
        if (selected.isEmpty) {
          selected = all.take(min(perLevel, all.length)).toList();
        }
      }
    }
    setState(() {
      _questions = selected;
      _index = 0;
      _loading = false;
      _answered = false;
      _selectedAnswer = null;
      _lastCorrect = false;
    });
  }

  Future<void> _logAnswer(Question q, String selected) async {
    final correct = (selected.trim() == q.correctAnswer.trim()) ? 1 : 0;
    // scoring by difficulty: Easy +1, Medium +3, Hard +5
    int pointsPerCorrect;
    switch (widget.difficulty.toLowerCase()) {
      case 'medium':
        pointsPerCorrect = 3;
        break;
      case 'hard':
        pointsPerCorrect = 5;
        break;
      default:
        pointsPerCorrect = 1;
    }
    final points = correct == 1 ? pointsPerCorrect : 0;
    final now = DateTime.now();
    final prog = Progress(
      profileID: widget.profileId,
      subjID: widget.subjID,
      questionID: q.questionID ?? 0,
      datePlayed: now.toIso8601String(),
      timeOn: now.toIso8601String(),
      timeOut: now.toIso8601String(),
      difficulty: widget.difficulty,
      level: widget.level,
      points: points,
      playerAnswer: selected,
      isCorrect: correct,
      runID: _runId,
    );
    await _pRepo.add(prog);
  }

  // summarise only answers from this run; return whether the run passed (>=70% correct)
  Future<bool> _summarizeLevel() async {
    final entries = await _pRepo.getByProfileAndRun(widget.profileId, _runId);
    final filtered = entries.where(
      (p) =>
          p.subjID == widget.subjID &&
          p.difficulty == widget.difficulty &&
          p.level == widget.level,
    );
    final totalAnswers = filtered.length;
    final correctCount = filtered.where((p) => p.isCorrect == 1).length;
    final percent = totalAnswers == 0 ? 0.0 : (correctCount / totalAnswers);
    final passed = percent >= 0.7;

    // compute total points for this run/level
    final totalPoints = filtered.fold<int>(0, (s, p) => s + (p.points));

    final lastQId = _questions.isNotEmpty
        ? (_questions.last.questionID ?? 0)
        : 0;
    final now = DateTime.now();
    final summary = Progress(
      profileID: widget.profileId,
      subjID: widget.subjID,
      questionID: lastQId,
      datePlayed: now.toIso8601String(),
      timeOn: now.toIso8601String(),
      timeOut: now.toIso8601String(),
      difficulty: widget.difficulty,
      level: widget.level,
      points: totalPoints,
      progressLevel: passed ? 'completed' : 'failed',
      isCorrect: null,
      runID: _runId,
    );
    await _pRepo.add(summary);
    return passed;
  }

  Future<void> _choose(String selected) async {
    if (_answered) return; // prevent double-tap
    final q = _questions[_index];
    await _logAnswer(q, selected);
    final correct = selected.trim() == q.correctAnswer.trim();
    setState(() {
      _answered = true;
      _selectedAnswer = selected;
      _lastCorrect = correct;
    });

    // If this was the last question, summarize and show completion modal with pass/fail
    if (_index >= _questions.length - 1) {
      final passed = await _summarizeLevel();
      _onLevelComplete(passed);
      return;
    }
    // otherwise wait for user to press Next
  }

  void _nextQuestion() {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _answered = false;
        _selectedAnswer = null;
        _lastCorrect = false;
      });
    } else {
      // safety: summarize & complete
      _summarizeLevel().then((passed) => _onLevelComplete(passed));
    }
  }

  void _onLevelComplete(bool passed) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(passed ? 'Level Passed' : 'Level Failed'),
        content: Text(
          passed
              ? 'You passed this level (>= 70% correct). What do you want to do next?'
              : 'You did not reach 70% correct. Try again or quit.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(c).pop(); // close dialog
              // restart same level with a fresh run
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => GameContent(
                    subjID: widget.subjID,
                    subjName: widget.subjName,
                    difficulty: widget.difficulty,
                    level: widget.level,
                    profileId: widget.profileId,
                  ),
                ),
              );
            },
            child: const Text('Try Again'),
          ),
          if (passed)
            ElevatedButton(
              onPressed: () {
                Navigator.of(c).pop(); // close dialog

                // If this was the boss, pop this GameContent and return success to the caller (LevelsScreen)
                if (widget.level == 99) {
                  Navigator.of(context).pop(true); // indicate boss completed
                  return;
                }

                // next level logic: 1..4 -> +1, 5 -> boss (99)
                final int nextLevel = (widget.level >= 1 && widget.level < 5)
                    ? widget.level + 1
                    : 99;

                // replace current GameContent with the next level route
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => GameContent(
                      subjID: widget.subjID,
                      subjName: widget.subjName,
                      difficulty: widget.difficulty,
                      level: nextLevel,
                      profileId: widget.profileId,
                    ),
                  ),
                );
              },
              child: const Text('Next Level'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(c).pop(); // close dialog
              // Return to the previous route and send a result so the Levels screen can refresh.
              Navigator.of(context).pop(false);
            },
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.subjName)),
        body: const Center(child: Text('No questions for this level')),
      );
    }

    // safety: ensure index in range
    if (_index < 0) _index = 0;
    if (_index >= _questions.length) {
      // already completed; show a placeholder while dialog is shown
      return Scaffold(
        appBar: AppBar(title: Text(widget.subjName)),
        body: const Center(child: Text('Level complete...')),
      );
    }

    final q = _questions[_index];
    final options = [q.option1, q.option2, q.option3, q.option4]..shuffle(_rnd);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subjName} - ${widget.difficulty} L${widget.level == 99 ? "Boss" : widget.level}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              'Question ${_index + 1} / ${_questions.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  q.questionText,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // options
            ...options.map((opt) {
              final disabled = _answered;
              final isSelected = _selectedAnswer == opt;
              Color? bg;
              if (_answered) {
                if (opt == q.correctAnswer) {
                  bg = Colors.green.shade200;
                } else if (isSelected && !_lastCorrect) {
                  bg = Colors.red.shade200;
                }
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  onPressed: disabled ? null : () => _choose(opt),
                  style: ElevatedButton.styleFrom(backgroundColor: bg),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(opt),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            if (_answered)
              Column(
                children: [
                  if (!_lastCorrect &&
                      q.correctExplanation != null &&
                      q.correctExplanation!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Explanation: ${q.correctExplanation}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _lastCorrect ? 'Correct!' : 'Incorrect',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _lastCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _index < _questions.length - 1
                            ? _nextQuestion
                            : null,
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
