import '../../repositories/game_repository.dart';
import '../../repositories/progress_repository.dart';
import '../game_loop/feedback_messages.dart';
import '../../models/progress.dart';

enum GamePhase { loading, cutsceneStart, gameplay, cutsceneEnd, completed }

enum AnswerResult { none, correct, wrong }

class GameController {
  final GameRepository repository;
  final ProgressRepository progressRepo = ProgressRepository();
  final int subjID;
  final String difficulty;
  final int level;
  final bool isBossLevel;
  final int profileID;

  List<GameQuestion> _questions = [];
  int currentIndex = 0;
  int correctCount = 0;

  GamePhase phase = GamePhase.loading;
  AnswerResult lastAnswerResult = AnswerResult.none;
  bool showingExplanation = false;
  String currentExplanation = '';

  void Function()? onUpdate;

  int passingScore = 0;

  GameController({
    required this.repository,
    required this.subjID,
    required this.difficulty,
    required this.level,
    required this.isBossLevel,
    required this.profileID,
  });

  /// Initialize questions and show intro cutscene
  Future<void> init() async {
    _questions = await repository.loadQuestions(
      subjID: subjID,
      difficulty: difficulty,
      level: level,
      isBoss: isBossLevel,
    );

    if (isBossLevel) {
      passingScore = _questions.length < 7 ? _questions.length : 7;
    } else {
      passingScore = _questions.length < 3 ? _questions.length : 3;
    }

    // for debugging
    //print('[GameController] Loaded ${_questions.length} questions');
    //print('[GameController] Passing score: $passingScore');

    phase = GamePhase.cutsceneStart;
    currentExplanation = FeedbackMessages.intro();
    _notify();
  }

  GameQuestion get currentQuestion => _questions[currentIndex];
  bool get hasQuestions => _questions.isNotEmpty;
  bool get isLastQuestion => currentIndex == _questions.length - 1;

  void _notify() => onUpdate?.call();

  /// Start the gameplay phase
  void startGameplay() {
    phase = GamePhase.gameplay;
    showingExplanation = false;
    lastAnswerResult = AnswerResult.none;
    correctCount = 0;
    _notify();
  }

  /// Submit an answer for the current question
  void submitAnswer(int index) {
    final correct = index == currentQuestion.correctIndex;
    lastAnswerResult = correct ? AnswerResult.correct : AnswerResult.wrong;

    if (correct) correctCount++;

    showingExplanation = true;
    currentExplanation = correct
        ? FeedbackMessages.correct()
        : FeedbackMessages.incorrect();

    _notify();
  }

  /// Move to next question or complete the level if last
  void nextQuestionOrRetry() {
    showingExplanation = false;
    lastAnswerResult = AnswerResult.none;

    if (!isLastQuestion) {
      currentIndex++;
      currentExplanation = FeedbackMessages.intro();
    } else {
      _completeLevel();
    }

    _notify();
  }

  /// Handle level completion and save progress
  void _completeLevel() async {
    final passed = correctCount >= passingScore;

    if (passed) {
      phase = GamePhase.completed;
      currentExplanation = FeedbackMessages.levelComplete();

      final now = DateTime.now();
      final completion = Progress(
        profileID: profileID,
        subjID: subjID,
        questionID: _questions.isNotEmpty ? _questions.last.id : 0,
        datePlayed: now.toIso8601String(),
        timeOn: now.toIso8601String(),
        timeOut: now.toIso8601String(),
        difficulty: difficulty,
        level: level,
        points: correctCount,
        progressLevel: 'completed',
        isCorrect: null,
        runID: now.toIso8601String(),
      );

      await progressRepo.add(completion);
    } else {
      phase = GamePhase.cutsceneEnd;
      currentExplanation = FeedbackMessages.retry();
    }

    _notify();
  }

  /// Finish a cutscene (intro or retry)
  void finishCutscene() {
    if (phase == GamePhase.cutsceneStart) {
      startGameplay();
    } else if (phase == GamePhase.cutsceneEnd) {
      currentIndex = 0;
      correctCount = 0;
      phase = GamePhase.cutsceneStart;
      showingExplanation = false;
      lastAnswerResult = AnswerResult.none;
      currentExplanation = FeedbackMessages.intro();
    }

    _notify();
  }

  /// Replay the level (manual retry)
  void retryLevel() {
    currentIndex = 0;
    correctCount = 0;
    phase = GamePhase.cutsceneStart;
    showingExplanation = false;
    lastAnswerResult = AnswerResult.none;
    currentExplanation = FeedbackMessages.intro();
    _notify();
  }
}
