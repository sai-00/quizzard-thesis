class Question {
  final int? questionID;
  final int subjID;
  final String questionText;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final String correctAnswer;
  final String? correctExplanation;
  final String? difficulty;

  Question({
    this.questionID,
    required this.subjID,
    required this.questionText,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    required this.correctAnswer,
    this.correctExplanation,
    this.difficulty,
  });

  factory Question.fromMap(Map<String, dynamic> m) => Question(
    questionID: m['questionID'] as int?,
    subjID: m['subjID'] as int,
    questionText: m['questionText'] as String,
    option1: m['option1'] as String,
    option2: m['option2'] as String,
    option3: m['option3'] as String,
    option4: m['option4'] as String,
    correctAnswer: m['correctAnswer'] as String,
    correctExplanation: m['correctExplanation'] as String?,
    difficulty: m['difficulty'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (questionID != null) 'questionID': questionID,
    'subjID': subjID,
    'questionText': questionText,
    'option1': option1,
    'option2': option2,
    'option3': option3,
    'option4': option4,
    'correctAnswer': correctAnswer,
    'correctExplanation': correctExplanation,
    'difficulty': difficulty,
  };
}
