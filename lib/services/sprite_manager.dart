import 'dart:async';
import '../screens/game_loop/game_controller.dart';

enum SubjectType { science, math, reading }

enum SpriteState { neutral, neutralTalking, correct, wrong }

class SpriteFrame {
  final String spriteAsset;
  final String backgroundAsset;

  SpriteFrame({required this.spriteAsset, required this.backgroundAsset});
}

class SpriteManager {
  final SubjectType subject;
  final String difficulty;
  final int level;

  Timer? _talkTimer;

  SpriteManager({
    required this.subject,
    required this.difficulty,
    required this.level,
  });

  static const Map<String, String> spriteAlias = {
    // Science
    'sci_neutral': 'assets/art/sprites/sci/sci-neutral.png',
    'sci_talking': 'assets/art/sprites/sci/sci-neutral-speaking.png',
    'sci_correct': 'assets/art/sprites/sci/sci-correct-answer.png',
    'sci_wrong': 'assets/art/sprites/sci/sci-wrong-answer.png',

    // Math
    'math_neutral': 'assets/art/sprites/math/math-neutral.png',
    'math_talking': 'assets/art/sprites/math/math-neutral-speaking.png',
    'math_correct': 'assets/art/sprites/math/math-correct-answer.png',
    'math_wrong': 'assets/art/sprites/math/math-wrong-answer.png',

    // Reading
    'eng_neutral': 'assets/art/sprites/eng/eng-neutral.png',
    'eng_talking': 'assets/art/sprites/eng/eng-neutral-speaking.png',
    'eng_correct': 'assets/art/sprites/eng/eng-correct-answer.png',
    'eng_wrong': 'assets/art/sprites/eng/eng-wrong-answer.png',
  };

  SpriteFrame initialFrame() => SpriteFrame(
    spriteAsset: _spriteFor(SpriteState.neutral),
    backgroundAsset: _backgroundFor(),
  );

  SpriteFrame correctAnswerFrame() => SpriteFrame(
    spriteAsset: _spriteFor(SpriteState.correct),
    backgroundAsset: _backgroundFor(),
  );

  SpriteFrame wrongAnswerFrame() => SpriteFrame(
    spriteAsset: _spriteFor(SpriteState.wrong),
    backgroundAsset: _backgroundFor(),
  );

  void dispose() => _stopTalking();

  /// Show a neutral talking animation briefly
  void showNeutralTalking(void Function(SpriteFrame) onUpdate) {
    _stopTalking();

    onUpdate(
      SpriteFrame(
        spriteAsset: _spriteFor(SpriteState.neutralTalking),
        backgroundAsset: _backgroundFor(),
      ),
    );

    _talkTimer = Timer(const Duration(seconds: 1), () {
      onUpdate(
        SpriteFrame(
          spriteAsset: _spriteFor(SpriteState.neutral),
          backgroundAsset: _backgroundFor(),
        ),
      );
      _talkTimer = null;
    });
  }

  void _stopTalking() {
    _talkTimer?.cancel();
    _talkTimer = null;
  }

  /// NEW: Determine sprite frame automatically from game state
  void showCurrentStateFrame({
    required GamePhase phase,
    required bool showingExplanation,
    required AnswerResult lastAnswer,
    required void Function(SpriteFrame) onUpdate,
  }) {
    if (showingExplanation) {
      // Show correct/wrong sprite
      if (lastAnswer == AnswerResult.correct) {
        onUpdate(correctAnswerFrame());
      } else if (lastAnswer == AnswerResult.wrong) {
        onUpdate(wrongAnswerFrame());
      } else {
        onUpdate(initialFrame());
      }
    } else {
      // Neutral talking for gameplay or cutscenes
      showNeutralTalking(onUpdate);
    }
  }

  String _spriteFor(SpriteState state) {
    String key;
    switch (subject) {
      case SubjectType.science:
        key = [
          'sci_neutral',
          'sci_talking',
          'sci_correct',
          'sci_wrong',
        ][state.index];
        break;
      case SubjectType.math:
        key = [
          'math_neutral',
          'math_talking',
          'math_correct',
          'math_wrong',
        ][state.index];
        break;
      case SubjectType.reading:
        key = [
          'eng_neutral',
          'eng_talking',
          'eng_correct',
          'eng_wrong',
        ][state.index];
        break;
    }
    return spriteAlias[key]!;
  }

  String _backgroundFor() {
    switch (subject) {
      case SubjectType.science:
        return 'assets/art/bgs/sci/sci-${difficulty.toLowerCase()}.png';
      case SubjectType.math:
        return level == 99
            ? 'assets/art/bgs/math/math-boss.png'
            : 'assets/art/bgs/math/math-hall.png';
      case SubjectType.reading:
        return 'assets/art/bgs/eng/eng-bg.png';
    }
  }

  /// Get background asset without requiring a sprite frame
  String getBackgroundAsset() => _backgroundFor();
}
