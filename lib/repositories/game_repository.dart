import '../db/quizzard_db.dart';

class GameQuestion {
  final int id;
  final String question;
  final List<String> choices;
  final int correctIndex;
  final String correctExplanation;

  GameQuestion({
    required this.id,
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.correctExplanation,
  });
}

class GameRepository {
  /// Loads questions filtered by subject and difficulty.
  /// Normal levels: 5 questions; Boss levels: 10 questions.
  Future<List<GameQuestion>> loadQuestions({
    required int subjID,
    required String difficulty,
    required int level,
    bool isBoss = false,
  }) async {
    final db = await QuizzardDb.instance.db;

    // Fetch all questions for this subject/difficulty
    final rows = await db.query(
      'questionList',
      where: 'subjID = ? AND difficulty = ?',
      whereArgs: [subjID, difficulty],
    );

    // Convert rows to GameQuestion
    final allQuestions = rows.map((r) {
      final options = [
        r['option1'] as String,
        r['option2'] as String,
        r['option3'] as String,
        r['option4'] as String,
      ];
      final correct = r['correctAnswer'] as String;
      final correctExplanation =
          r['correctExplanation'] as String? ?? 'Good job!';
      return GameQuestion(
        id: r['questionID'] as int,
        question: r['questionText'] as String,
        choices: options,
        correctIndex: options.indexOf(correct),
        correctExplanation: correctExplanation,
      );
    }).toList();

    if (allQuestions.isEmpty) return [];

    // Determine how many questions per level
    final int perLevel = 5;
    List<GameQuestion> selected;

    if (isBoss || level == 99) {
      allQuestions.shuffle();
      selected = allQuestions
          .take(allQuestions.length < 10 ? allQuestions.length : 10)
          .toList();
    } else {
      // Normal levels: slice based on level
      final start = (level - 1) * perLevel;
      if (start >= allQuestions.length) {
        selected = allQuestions
            .take(
              allQuestions.length < perLevel ? allQuestions.length : perLevel,
            )
            .toList();
      } else {
        selected = allQuestions.skip(start).take(perLevel).toList();
        if (selected.isEmpty) {
          selected = allQuestions
              .take(
                allQuestions.length < perLevel ? allQuestions.length : perLevel,
              )
              .toList();
        }
      }
    }

    // Shuffle the selected questions for randomness
    selected.shuffle();

    return selected;
  }
}
