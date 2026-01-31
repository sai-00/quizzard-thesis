// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
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
    final filename =
        '${widget.subject.name}_${widget.difficulty.toLowerCase()}.csv';

    // Prefer custom CSV placed in the app documents directory under
    // `custom/<subject>/`. If not found, fall back to bundled asset at
    // `lib/screens/game_loop/scenes/<subject>/<subject>_<difficulty>.csv`.
    final docsDir = await getApplicationDocumentsDirectory();
    final customPath =
        '${docsDir.path}${Platform.pathSeparator}custom${Platform.pathSeparator}${widget.subject.name}${Platform.pathSeparator}$filename';

    debugPrint('SceneRenderer: checking custom CSV at: $customPath');

    String raw;
    final customFile = File(customPath);
    if (await customFile.exists()) {
      // Read bytes and attempt to decode with common encodings (UTF-8, UTF-16 LE/BE, Latin1)
      final bytes = await customFile.readAsBytes();
      try {
        raw = utf8.decode(bytes);
      } on FormatException catch (_) {
        // Check BOMs
        if (bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF) {
          raw = utf8.decode(bytes.sublist(3));
        } else if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
          // UTF-16 LE
          final units = <int>[];
          for (var i = 2; i + 1 < bytes.length; i += 2) {
            units.add(bytes[i] | (bytes[i + 1] << 8));
          }
          raw = String.fromCharCodes(units);
        } else if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
          // UTF-16 BE
          final units = <int>[];
          for (var i = 2; i + 1 < bytes.length; i += 2) {
            units.add((bytes[i] << 8) | bytes[i + 1]);
          }
          raw = String.fromCharCodes(units);
        } else {
          // fallback to latin1 or permissive utf8
          try {
            raw = latin1.decode(bytes);
          } catch (_) {
            raw = utf8.decode(bytes, allowMalformed: true);
          }
        }
      }
    } else {
      final assetPath =
          'lib/screens/game_loop/scenes/${widget.subject.name}/$filename';
      raw = await rootBundle.loadString(assetPath);
    }
    // Normalize common problematic characters (curly quotes, non-breaking spaces,
    // BOM) to simple ASCII equivalents so the UI fonts render them reliably.
    raw = raw.replaceAll('\uFEFF', ''); // remove BOM if present
    raw = raw.replaceAll('\u00A0', ' '); // non-breaking space -> regular space
    // curly/smart single quotes -> ASCII apostrophe
    raw = raw.replaceAll('\u2018', "'");
    raw = raw.replaceAll('\u2019', "'");
    raw = raw.replaceAll('\u201B', "'");
    raw = raw.replaceAll('\u02BC', "'");
    raw = raw.replaceAll('\u2032', "'");
    // curly double quotes -> ASCII double quote
    raw = raw.replaceAll('\u201C', '"');
    raw = raw.replaceAll('\u201D', '"');
    // other common right single quotation mark
    raw = raw.replaceAll('\u2017', "'");

    // Replace Unicode replacement character (�) and common control-code
    // leftovers from Windows-1252-like encodings with sensible equivalents.
    raw = raw.replaceAll('\uFFFD', "'");
    raw = raw.replaceAll('\u0091', "'");
    raw = raw.replaceAll('\u0092', "'");
    raw = raw.replaceAll('\u0093', '"');
    raw = raw.replaceAll('\u0094', '"');
    raw = raw.replaceAll('\u0096', '-');
    raw = raw.replaceAll('\u0097', '-');

    final rows = const CsvToListConverter().convert(raw);

    int startIndex = 0;
    if (rows.isNotEmpty) {
      final firstCell = rows.first.isNotEmpty ? rows.first[0].toString() : '';
      if (int.tryParse(firstCell) == null) startIndex = 1;
    }

    final dataRows = rows.skip(startIndex);

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
