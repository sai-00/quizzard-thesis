// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../../services/sprite_manager.dart';

enum ScenePlacement { beginning, end }

class SceneLine {
  final int level;
  final ScenePlacement placement;
  final int order;
  final String dialogue;
  final SpriteState? spriteState;

  SceneLine({
    required this.level,
    required this.placement,
    required this.order,
    required this.dialogue,
    required this.spriteState,
  });
}

class SceneRenderer extends StatefulWidget {
  final SubjectType subject;
  final String difficulty;
  final int level;
  final ScenePlacement placement;
  final SpriteManager spriteManager;
  final void Function(SpriteFrame?) onSpriteUpdate;
  final VoidCallback onFinished;
  final Color textBoxColor;
  final VoidCallback? onNext;
  final VoidCallback? onNoLines;
  final ValueChanged<bool>? onLoaded;
  final String? backgroundAsset;

  const SceneRenderer({
    super.key,
    required this.subject,
    required this.difficulty,
    required this.level,
    required this.placement,
    required this.spriteManager,
    required this.onSpriteUpdate,
    required this.onFinished,
    required this.textBoxColor,
    this.onNext,
    this.onNoLines,
    this.onLoaded,
    this.backgroundAsset,
  });

  @override
  State<SceneRenderer> createState() => SceneRendererState();
}

class SceneRendererState extends State<SceneRenderer> {
  List<SceneLine> _lines = [];
  int _index = 0;
  bool _loading = true;
  bool _noLinesNotified = false;

  // Public getter so parent can check whether CSV has lines
  bool get hasLines => _lines.isNotEmpty;

  void nextLine() => _next();

  @override
  void initState() {
    super.initState();
    _loadCsv();
  }

  Future<void> _loadCsv() async {
    final path =
        'lib/screens/game_loop/scenes/${widget.subject.name}/${widget.subject.name}_${widget.difficulty.toLowerCase()}.csv';
    final raw = await rootBundle.loadString(path);
    final rows = const CsvToListConverter().convert(raw);

    final dataRows = rows.skip(1);

    final lines = <SceneLine>[];

    for (final row in dataRows) {
      if (row.length < 5) continue;

      final level = int.tryParse(row[0].toString()) ?? -1;
      final placementStr = row[1].toString().toLowerCase();
      final order = int.tryParse(row[2].toString()) ?? 0;
      final dialogue = row[3].toString();
      final spriteStr = row[4].toString().toLowerCase();

      final placement = placementStr == 'end'
          ? ScenePlacement.end
          : ScenePlacement.beginning;

      if (level != widget.level || placement != widget.placement) continue;

      lines.add(
        SceneLine(
          level: level,
          placement: placement,
          order: order,
          dialogue: dialogue,
          spriteState: _spriteFromString(spriteStr),
        ),
      );
    }

    lines.sort((a, b) => a.order.compareTo(b.order));

    setState(() {
      _lines = lines;
      _loading = false;
    });

    // notify parent whether we loaded any lines
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onLoaded?.call(_lines.isNotEmpty);
    });

    if (_lines.isNotEmpty) {
      _applySprite(_lines.first.spriteState);
    }
  }

  SpriteState? _spriteFromString(String value) {
    final v = value.trim().toLowerCase();
    if (v.isEmpty || v == 'none' || v == 'null') return null;

    switch (v) {
      case 'talking':
        return SpriteState.neutralTalking;
      case 'correct':
        return SpriteState.correct;
      case 'wrong':
        return SpriteState.wrong;
      default:
        return null;
    }
  }

  void _applySprite(SpriteState? state) {
    if (state == null) {
      widget.onSpriteUpdate(null);
      return;
    }

    switch (state) {
      case SpriteState.correct:
        widget.onSpriteUpdate(widget.spriteManager.correctAnswerFrame());
        break;
      case SpriteState.wrong:
        widget.onSpriteUpdate(widget.spriteManager.wrongAnswerFrame());
        break;
      case SpriteState.neutralTalking:
        widget.spriteManager.showNeutralTalking(widget.onSpriteUpdate);
        break;
      case SpriteState.neutral:
        widget.onSpriteUpdate(widget.spriteManager.initialFrame());
        break;
    }
  }

  void _next() {
    if (_index + 1 >= _lines.length) {
      widget.onFinished();
      return;
    }

    setState(() => _index++);
    _applySprite(_lines[_index].spriteState);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_lines.isEmpty) {
      // No CSV lines for this placement: inform parent so it can proceed.
      if (!_noLinesNotified) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onNoLines?.call();
        });
        _noLinesNotified = true;
      }
      return const SizedBox.shrink();
    }

    final line = _lines[_index];

    return Stack(
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 80),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: widget.textBoxColor,
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
                line.dialogue,
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
        // Continue button for CSV-driven cutscenes
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (widget.onNext != null) {
                    widget.onNext!();
                  } else {
                    _next();
                  }
                },
                child: const Text('Continue', style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
