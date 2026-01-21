import 'dart:math';

class FeedbackMessages {
  static final _random = Random();

  static const List<String> correctAnswers = [
    "Good job!",
    "Nice work!",
    "You're on fire!",
    "Excellent!",
    "Correct!",
  ];

  static const List<String> incorrectAnswers = [
    "Oops, try again!",
    "Not quite, keep going!",
    "Almost there!",
    "Incorrect, you got this!",
    "Try another one!",
  ];

  static const List<String> retryLevel = [
    "Huh… let's try that again!",
    "Don't worry, let's go again!",
    "Let's give it another shot!",
    "Almost had it, try again!",
    "You can do this, let's retry!",
  ];

  static const List<String> _levelCompleteMessages = [
    "Level Complete! Great work!",
    "Awesome! Level finished!",
    "You did it! On to the next!",
    "Well done! Level cleared!",
    "Fantastic! Ready for the next one?",
  ];

  // Intro / start level messages
  static const List<String> _introMessages = [
    "Alright! Let's start the level!",
    "Here we go! Good luck!",
    "Time to shine! Let's go!",
    "Let's do this! Ready?",
    "Level starting! You got this!",
  ];

  static String correct() =>
      correctAnswers[_random.nextInt(correctAnswers.length)];

  static String incorrect() =>
      incorrectAnswers[_random.nextInt(incorrectAnswers.length)];

  static String retry() => retryLevel[_random.nextInt(retryLevel.length)];

  static String levelComplete() =>
      _levelCompleteMessages[_random.nextInt(_levelCompleteMessages.length)];

  static String intro() =>
      _introMessages[_random.nextInt(_introMessages.length)];
}
