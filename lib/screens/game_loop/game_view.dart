// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../../repositories/game_repository.dart';
import '../../services/sprite_manager.dart';
import 'game_controller.dart';
import '../game_loop/feedback_messages.dart';
import '../game_loop/scene_renderer.dart';
import '../game_loop/game_menu.dart';

class GameView extends StatefulWidget {
  final int subjID;
  final String subject;
  final String difficulty;
  final int level;
  final bool isBossLevel;
  final int profileID;

  const GameView({
    super.key,
    required this.subjID,
    required this.subject,
    required this.difficulty,
    required this.level,
    required this.isBossLevel,
    required this.profileID,
  });

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  late GameController controller;
  late SpriteManager spriteManager;
  SpriteFrame? frame;
  double spriteYOffset = 0.0;
  DateTime? _lastSpriteChange;

  final GlobalKey<SceneRendererState> _sceneKeyBeginning = GlobalKey();
  final GlobalKey<SceneRendererState> _sceneKeyEnd = GlobalKey();
  bool _csvBeginningFinished = false;
  bool _showingCsvEnd = false;
  bool _csvEndRequested = false;

  @override
  void initState() {
    super.initState();

    spriteManager = SpriteManager(
      subject: SubjectType.values.byName(widget.subject.toLowerCase()),
      difficulty: widget.difficulty,
      level: widget.isBossLevel ? 99 : widget.level,
    );

    controller = GameController(
      repository: GameRepository(),
      subjID: widget.subjID,
      difficulty: widget.difficulty,
      level: widget.level,
      isBossLevel: widget.isBossLevel,
      profileID: widget.profileID,
    );

    controller.onUpdate = () {
      if (!mounted) return;
      // When completed, request the end CSV to be evaluated. We don't
      // immediately show it because the SceneRenderer loads asynchronously;
      // instead we mount it offstage and wait for its onLoaded callback to
      // tell us whether it has lines to show. This prevents flicker while
      // ensuring end cutscenes with lines are displayed.
      if (controller.phase == GamePhase.completed) {
        _csvEndRequested = true;
        _showingCsvEnd = false;
      }

      debugPrint(
        '[GameView] onUpdate: phase=${controller.phase} showingExplanation=${controller.showingExplanation} lastAnswer=${controller.lastAnswerResult} _csvEndRequested=$_csvEndRequested _showingCsvEnd=$_showingCsvEnd',
      );

      setState(() {});
      _updateSpriteForState();
    };

    frame = spriteManager.initialFrame();
    controller.init().then((_) {
      // Only show neutral talking if not in cutscene
      if (controller.phase == GamePhase.gameplay) {
        spriteManager.showNeutralTalking(_updateSprite);
      }
    });
  }

  // new helper: target the appropriate SceneRenderer by placement
  void _csvRendererNext(ScenePlacement placement) {
    debugPrint('[GameView] csvRendererNext: placement=$placement');
    if (placement == ScenePlacement.beginning) {
      _sceneKeyBeginning.currentState?.nextLine();
    } else {
      _sceneKeyEnd.currentState?.nextLine();
    }
  }

  bool _csvHasLines(ScenePlacement placement) {
    final has =
        (placement == ScenePlacement.beginning
                ? _sceneKeyBeginning.currentState
                : _sceneKeyEnd.currentState)
            ?.hasLines ??
        false;
    debugPrint('[GameView] csvHasLines: placement=$placement has=$has');
    return has;
  }

  void _updateSprite(SpriteFrame? newFrame) {
    // Debounce / ignore redundant sprite updates to avoid rapid flicker.
    final newAsset = newFrame?.spriteAsset;
    final currentAsset = frame?.spriteAsset;
    final now = DateTime.now();

    debugPrint(
      '[GameView] updateSprite: newFrame=$newAsset current=$currentAsset',
    );

    // If identical asset, ignore
    if (newAsset != null && newAsset == currentAsset) {
      debugPrint('[GameView] updateSprite: identical asset, ignoring');
      return;
    }

    // If last change was very recent, ignore to throttle rapid changes
    if (_lastSpriteChange != null &&
        now.difference(_lastSpriteChange!).inMilliseconds < 100) {
      debugPrint(
        '[GameView] updateSprite: throttled (${now.difference(_lastSpriteChange!).inMilliseconds}ms)',
      );
      return;
    }

    _lastSpriteChange = now;

    setState(() {
      frame = newFrame;
      spriteYOffset = -20;
    });

    if (newFrame != null) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        setState(() => spriteYOffset = 0);
      });
    }
  }

  void _updateSpriteForState() {
    // Avoid changing the sprite while the CSV end is being requested or shown
    if (controller.phase == GamePhase.cutsceneStart ||
        controller.phase == GamePhase.cutsceneEnd ||
        (controller.phase == GamePhase.completed &&
            (_csvEndRequested || _showingCsvEnd))) {
      debugPrint(
        '[GameView] updateSpriteForState: skipping due to phase=${controller.phase} csvRequested=$_csvEndRequested showingCsv=$_showingCsvEnd',
      );
      return;
    }

    if (controller.showingExplanation) {
      _updateSprite(
        controller.lastAnswerResult == AnswerResult.correct
            ? spriteManager.correctAnswerFrame()
            : spriteManager.wrongAnswerFrame(),
      );
    } else {
      debugPrint('[GameView] updateSpriteForState: showing neutral talking');
      spriteManager.showNeutralTalking(_updateSprite);
    }
  }

  void _playNextLevel() {
    int nextLevel;
    bool nextBoss = false;

    if (widget.level < 5) {
      nextLevel = widget.level + 1;
    } else if (widget.level == 5) {
      // unlock boss
      nextLevel = 99;
      nextBoss = true;
    } else {
      // after boss, return to levels screen
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameView(
          subjID: widget.subjID,
          subject: widget.subject,
          difficulty: widget.difficulty,
          level: nextLevel,
          isBossLevel: nextBoss,
          profileID: widget.profileID,
        ),
      ),
    );
  }

  void _retryLevel() {
    debugPrint('[GameView] retryLevel pressed');
    // Reset controller state for a manual retry and update the UI.
    controller.retryLevel();
    setState(() {
      // show the neutral/initial frame for the retry cutscene immediately
      frame = spriteManager.initialFrame();
      spriteYOffset = 0;
      _csvBeginningFinished = false;
      _showingCsvEnd = false;
      _csvEndRequested = false;
      _lastSpriteChange = null;
    });

    // animate neutral talking for the cutscene (do this directly so the
    // sprite appears even during cutscene phases).
    spriteManager.showNeutralTalking(_updateSprite);
  }

  @override
  void dispose() {
    spriteManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        _buildPhase(),
        // Top menu: left = pause/menu, right = skip cutscene
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const GameMenu(),
                      );
                    },
                  ),
                ),

                // Skip cutscene button
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    // Display >> as requested
                    icon: const Text(
                      '>>',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      // If we're in the intro cutscene, skip into gameplay
                      if (controller.phase == GamePhase.cutsceneStart) {
                        setState(() {
                          _csvBeginningFinished = true;
                        });
                        controller.finishCutscene();
                      } else if (controller.phase == GamePhase.cutsceneEnd ||
                          controller.phase == GamePhase.completed) {
                        // Hide CSV end overlay if visible
                        setState(() {
                          _showingCsvEnd = false;
                          _csvEndRequested = false;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _csvCutscene(ScenePlacement placement) {
    // Choose onFinished/onNoLines handlers depending on placement so we can
    // sequence: CSV beginning -> view cutscene -> gameplay -> view end -> CSV end
    if (placement == ScenePlacement.beginning) {
      return SceneRenderer(
        subject: SubjectType.values.byName(widget.subject.toLowerCase()),
        difficulty: widget.difficulty,
        level: widget.level,
        placement: placement,
        spriteManager: spriteManager,
        onSpriteUpdate: _updateSprite,
        onFinished: () {
          setState(() => _csvBeginningFinished = true);
        },
        onNoLines: () {
          // If there are no CSV lines at the beginning, mark as finished so
          // the view cutscene shows immediately.
          setState(() => _csvBeginningFinished = true);
        },
        onNext: () => _csvRendererNext(placement),
        onLoaded: (hasLines) {
          // beginning placement: if there are no lines, mark finished
          if (!hasLines) setState(() => _csvBeginningFinished = true);
        },
        textBoxColor: _subjectColor(widget.subject),
        key: _sceneKeyBeginning,
      );
    }

    // end placement
    return SceneRenderer(
      subject: SubjectType.values.byName(widget.subject.toLowerCase()),
      difficulty: widget.difficulty,
      level: widget.level,
      placement: placement,
      spriteManager: spriteManager,
      onSpriteUpdate: _updateSprite,
      onFinished: () {
        // Hide CSV overlay when the CSV end finishes so the levelComplete UI
        // beneath becomes interactive (Next Level / Quit buttons).
        setState(() => _showingCsvEnd = false);
      },
      onNext: () => _csvRendererNext(placement),
      onNoLines: () {
        // If no CSV lines at end, just hide overlay immediately
        setState(() => _showingCsvEnd = false);
      },
      onLoaded: (hasLines) {
        // If the parent requested the end CSV (level completed), show the
        // overlay only when the renderer reports it actually has lines.
        if (controller.phase == GamePhase.completed) {
          setState(() {
            _showingCsvEnd = hasLines;
            // clear the request once handled
            _csvEndRequested = false;
          });
        }
      },
      textBoxColor: _subjectColor(widget.subject),
      key: _sceneKeyEnd,
    );
  }

  Widget _buildPhase() {
    switch (controller.phase) {
      case GamePhase.loading:
        return const Center(child: CircularProgressIndicator());
      case GamePhase.cutsceneStart:
        return Stack(
          children: [
            // show the view cutscene underneath; CSV beginning overlays it
            _cutscene(),
            if (!_csvBeginningFinished) _csvCutscene(ScenePlacement.beginning),
          ],
        );
      case GamePhase.cutsceneEnd:
        return Stack(
          children: [
            _cutscene(),
            if (_csvEndRequested || _showingCsvEnd)
              Offstage(
                offstage: !_showingCsvEnd,
                child: _csvCutscene(ScenePlacement.end),
              ),
          ],
        );
      case GamePhase.gameplay:
        return _gameplay();
      case GamePhase.completed:
        return Stack(
          children: [
            _levelComplete(),
            if (_csvEndRequested || _showingCsvEnd)
              Offstage(
                offstage: !_showingCsvEnd,
                child: _csvCutscene(ScenePlacement.end),
              ),
          ],
        );
    }
  }

  Widget _cutscene() {
    final isRetry =
        controller.phase == GamePhase.cutsceneEnd && controller.requiresRetry;

    final cutsceneText = controller.currentExplanation.isNotEmpty
        ? controller.currentExplanation
        : (isRetry ? FeedbackMessages.retry() : FeedbackMessages.intro());

    return Stack(
      children: [
        // Background
        Image.asset(
          spriteManager.getBackgroundAsset(),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        // Sprite
        if (frame != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: spriteYOffset),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) =>
                    Transform.translate(offset: Offset(0, value), child: child),
                child: Image.asset(
                  frame!.spriteAsset,
                  height: 500,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

        // VN-style text box
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: 130),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: _subjectColor(widget.subject),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                cutsceneText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Buttons
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isRetry
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _retryLevel,
                            child: const Text(
                              'Retry Level',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[850],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Quit',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            72,
                            39,
                            102,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // Handle sequencing for beginning and end CSV cutscenes.
                          if (controller.phase == GamePhase.cutsceneStart) {
                            // If CSV beginning hasn't finished yet, advance it if possible,
                            // otherwise mark it finished so the view cutscene shows.
                            if (!_csvBeginningFinished) {
                              if (_csvHasLines(ScenePlacement.beginning)) {
                                _csvRendererNext(ScenePlacement.beginning);
                              } else {
                                setState(() => _csvBeginningFinished = true);
                              }
                            } else {
                              controller.finishCutscene();
                            }
                            return;
                          }

                          if (controller.phase == GamePhase.cutsceneEnd) {
                            // If we're not yet showing the CSV end, start it when Continue
                            // is pressed and CSV lines exist; otherwise finish.
                            if (!_showingCsvEnd) {
                              if (_csvHasLines(ScenePlacement.end)) {
                                setState(() => _showingCsvEnd = true);
                              } else {
                                controller.finishCutscene();
                              }
                            } else {
                              // If CSV end is being shown, advance it.
                              if (_csvHasLines(ScenePlacement.end)) {
                                _csvRendererNext(ScenePlacement.end);
                              } else {
                                controller.finishCutscene();
                              }
                            }
                            return;
                          }

                          controller.finishCutscene();
                        },
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _levelComplete() {
    return Stack(
      children: [
        // Background (always display)
        Image.asset(
          spriteManager.getBackgroundAsset(),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Sprite floating above bottom (nullable)
        if (frame != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: spriteYOffset),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: child,
                  );
                },
                child: Image.asset(
                  frame!.spriteAsset,
                  height: 500,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

        // VN-style text box
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 130),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: _subjectColor(widget.subject),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                FeedbackMessages.levelComplete(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Buttons
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 72, 39, 102),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _playNextLevel,
                      child: const Text(
                        'Next Level',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[850],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Quit',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gameplay() {
    if (!controller.hasQuestions) {
      return const Center(child: Text('No questions available.'));
    }

    final q = controller.currentQuestion;

    return Stack(
      children: [
        // Background (always display)
        Image.asset(
          spriteManager.getBackgroundAsset(),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Sprite floating slightly above bottom (nullable)
        if (frame != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 70,
              ), // float above text box
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: spriteYOffset),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, value),
                    child: child,
                  );
                },
                child: Image.asset(
                  frame!.spriteAsset,
                  height: 500,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

        // Text box (floating above buttons)
        // Progress bar and question counter (top)
        Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Question ${controller.answeredCount}/${controller.totalQuestions}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: controller.totalQuestions > 0
                          ? (controller.answeredCount /
                                controller.totalQuestions)
                          : 0,
                      minHeight: 6,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.purpleAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: controller.showingExplanation
                  ? 130
                  : 300, // float above buttons or above choices
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: _subjectColor(widget.subject),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                controller.showingExplanation
                    ? controller.currentExplanation
                    : q.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Choices or Continue button
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: controller.showingExplanation
                  ? SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            72,
                            39,
                            102,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: controller.nextQuestionOrRetry,
                        child: const Text(
                          'Continue',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    )
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.6,
                      padding: EdgeInsets.zero,
                      children: List.generate(4, (i) {
                        final choiceColors = <Color>[
                          const Color.fromARGB(255, 39, 87, 140), // blue
                          const Color.fromARGB(255, 83, 30, 26), // red
                          const Color.fromARGB(255, 60, 179, 113), // green
                          const Color.fromARGB(255, 181, 113, 18), // orange
                        ];

                        final baseColor = choiceColors[i];

                        return ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color>((
                                  states,
                                ) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return baseColor.withOpacity(0.5);
                                  }
                                  if (states.contains(MaterialState.pressed)) {
                                    return HSLColor.fromColor(
                                      baseColor,
                                    ).withLightness(0.45).toColor();
                                  }
                                  return baseColor;
                                }),
                            elevation:
                                MaterialStateProperty.resolveWith<double>(
                                  (states) =>
                                      states.contains(MaterialState.pressed)
                                      ? 2
                                      : 4,
                                ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          onPressed: () => controller.submitAnswer(i),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                q.choices[i],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper function for per-subject text box color
  Color _subjectColor(String subject) {
    switch (subject.toLowerCase()) {
      case 'math':
        return const Color.fromARGB(255, 33, 53, 56);
      case 'reading':
        return const Color.fromARGB(255, 43, 27, 54);
      case 'science':
        return const Color.fromARGB(255, 66, 12, 12);
      default:
        return Colors.black87;
    }
  }
}
