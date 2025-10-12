class Progress {
  int? gameProgID;
  int profileID;
  int subjID;
  int questionID;
  String? datePlayed; // ISO string
  String? timeOn;
  String? timeOut;
  String? difficulty; // Easy/Medium/Hard
  int? level; // level number (1..5, boss maybe 99)
  int points;
  String? progressLevel;
  String? highestLevel;
  int? easyScore;
  int? medScore;
  int? hardScore;
  String? playerAnswer;
  int? isCorrect; // 1 or 0
  String? runID; // identifier for a single play run

  Progress({
    this.gameProgID,
    required this.profileID,
    required this.subjID,
    required this.questionID,
    this.datePlayed,
    this.timeOn,
    this.timeOut,
    this.difficulty,
    this.level,
    this.points = 0,
    this.progressLevel,
    this.highestLevel,
    this.easyScore,
    this.medScore,
    this.hardScore,
    this.playerAnswer,
    this.isCorrect,
    this.runID,
  });

  factory Progress.fromMap(Map<String, dynamic> m) => Progress(
    gameProgID: m['gameProgID'] as int?,
    profileID: m['profileID'] as int,
    subjID: m['subjID'] as int? ?? (m['subjId'] as int? ?? 0),
    questionID: m['questionID'] as int,
    datePlayed: m['datePlayed'] as String?,
    timeOn: m['timeOn'] as String?,
    timeOut: m['timeOut'] as String?,
    difficulty: m['difficulty'] as String?,
    level: m['level'] as int?,
    points: (m['points'] as int?) ?? 0,
    progressLevel: m['progressLevel'] as String?,
    highestLevel: m['highestLevel'] as String?,
    easyScore: m['easyScore'] as int?,
    medScore: m['medScore'] as int?,
    hardScore: m['hardScore'] as int?,
    playerAnswer: m['playerAnswer'] as String?,
    isCorrect: m['isCorrect'] as int?,
    runID: m['runID'] as String?,
  );

  Map<String, dynamic> toMap() => {
    if (gameProgID != null) 'gameProgID': gameProgID,
    'profileID': profileID,
    'subjID': subjID,
    'questionID': questionID,
    'datePlayed': datePlayed,
    'timeOn': timeOn,
    'timeOut': timeOut,
    'difficulty': difficulty,
    'level': level,
    'points': points,
    'progressLevel': progressLevel,
    'highestLevel': highestLevel,
    'easyScore': easyScore,
    'medScore': medScore,
    'hardScore': hardScore,
    'playerAnswer': playerAnswer,
    'isCorrect': isCorrect,
    'runID': runID,
  };
}
