import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart'; // for debugPrint
import '../models/question.dart';
import '../repositories/question_repository.dart';

/// Normalize raw CSV content to mitigate Excel/encoding/platform differences.
/// - Decodes bytes using UTF-8 (with fallback to Latin1)
/// - Removes BOMs
/// - Replaces curly quotes, non-breaking spaces, and common Windows-1252 leftovers
/// - Normalizes line endings to LF
/// - Handles Excel-exported rows where an entire row is wrapped in double-quotes
///   and cells double-up internal quotes (""") by unwrapping and unescaping.
String normalizeCsvRawFromBytes(Uint8List bytes) {
  String raw;
  try {
    raw = utf8.decode(bytes);
  } on FormatException {
    // try removing UTF-8 BOM if present
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      raw = utf8.decode(bytes.sublist(3));
    } else {
      // fallback to latin1 which will preserve bytes rather than throwing
      raw = latin1.decode(bytes);
    }
  }

  return normalizeCsvRawFromString(raw);
}

Future<String> normalizeCsvFile(String path) async {
  final bytes = await File(path).readAsBytes();
  return normalizeCsvRawFromBytes(bytes);
}

String normalizeCsvRawFromString(String raw) {
  // remove BOM and normalize common problematic characters using codepoints
  raw = raw.replaceAll(String.fromCharCode(0xFEFF), '');
  raw = raw.replaceAll(String.fromCharCode(0x00A0), ' ');
  raw = raw.replaceAll(String.fromCharCode(0x2018), "'");
  raw = raw.replaceAll(String.fromCharCode(0x2019), "'");
  raw = raw.replaceAll(String.fromCharCode(0x201B), "'");
  raw = raw.replaceAll(String.fromCharCode(0x02BC), "'");
  raw = raw.replaceAll(String.fromCharCode(0x2032), "'");
  raw = raw.replaceAll(String.fromCharCode(0x201C), '"');
  raw = raw.replaceAll(String.fromCharCode(0x201D), '"');
  raw = raw.replaceAll(String.fromCharCode(0x2017), "'");
  raw = raw.replaceAll(String.fromCharCode(0xFFFD), "'");
  raw = raw.replaceAll(String.fromCharCode(0x0091), "'");
  raw = raw.replaceAll(String.fromCharCode(0x0092), "'");
  raw = raw.replaceAll(String.fromCharCode(0x0093), '"');
  raw = raw.replaceAll(String.fromCharCode(0x0094), '"');
  raw = raw.replaceAll(String.fromCharCode(0x0096), '-');
  raw = raw.replaceAll(String.fromCharCode(0x0097), '-');

  // Normalize line endings to unix-style
  raw = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

  // Process lines: detect Excel-exported rows like:
  //  "col1","col2 with ""quotes""","col3"
  // or rows that are entirely wrapped in an extra pair of quotes.
  final lines = raw.split('\n');
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    if (line.isEmpty) continue;

    // If a line appears to be a row-wrapped export (starts & ends with quote and
    // contains the quoted-field separator '","'), unwrap and unescape.
    if (line.length >= 2 &&
        line.startsWith('"') &&
        line.endsWith('"') &&
        line.contains('","')) {
      line = line.substring(1, line.length - 1);
      // Unescape doubled quotes inside fields
      line = line.replaceAll('""', '"');
      // Replace the quoted-field separators with plain commas so the lightweight parser sees separators
      line = line.replaceAll('","', ',');
      lines[i] = line;
      continue;
    }

    // In other cases, still collapse doubled double-quotes which Excel uses to escape
    // internal quotes inside a quoted field.
    if (line.contains('""')) {
      lines[i] = line.replaceAll('""', '"');
    }
  }

  return lines.join('\n');
}

class CsvSyncService {
  final QuestionRepository _questionRepo = QuestionRepository();

  /// Lightweight CSV parser that returns rows of fields.
  /// Handles quoted fields with commas and double-quote escaping ("").
  List<List<String>> _parseCsv(String input) {
    final List<List<String>> rows = [];
    final buffer = StringBuffer();
    final current = <String>[];
    bool inQuotes = false;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == '"') {
        // lookahead for escaped quote
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          buffer.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (!inQuotes && (ch == ',')) {
        current.add(buffer.toString());
        buffer.clear();
        continue;
      }
      if (!inQuotes && (ch == '\r')) {
        // ignore CR, handle on LF
        continue;
      }
      if (!inQuotes && (ch == '\n')) {
        current.add(buffer.toString());
        buffer.clear();
        rows.add(List<String>.from(current));
        current.clear();
        continue;
      }
      buffer.write(ch);
    }
    // flush remaining
    if (buffer.isNotEmpty || current.isNotEmpty) {
      current.add(buffer.toString());
      rows.add(List<String>.from(current));
    }
    return rows;
  }

  /// Import CSV content provided as a string.
  /// Expects a header row. Header names accepted (case-insensitive):
  /// subjID, questionText, option1, option2, option3, option4,
  /// correctAnswer, correctExplanation, difficulty
  Future<void> importCsvString(
    String csvContent, {
    int defaultSubjID = 1,
  }) async {
    // Ensure content normalized (handles BOMs, Excel quoting, weird quotes)
    csvContent = normalizeCsvRawFromString(csvContent);

    if (csvContent.trim().isEmpty) {
      debugPrint('CSV import aborted: file is empty');
      return;
    }

    final rows = _parseCsv(csvContent);

    debugPrint('CSV rows parsed: ${rows.length}');

    if (rows.isEmpty) {
      debugPrint('CSV import aborted: no rows found');
      return;
    }

    // Detect header row
    final hasHeader = rows.first.any(
      (cell) =>
          cell.toLowerCase().contains('question') ||
          cell.toLowerCase().contains('option'),
    );

    final List<String> headerRow = hasHeader
        ? rows.first.map((e) => e.trim().toLowerCase()).toList()
        : [
            'subjid',
            'questiontext',
            'option1',
            'option2',
            'option3',
            'option4',
            'correctanswer',
            'correctexplanation',
            'difficulty',
          ];

    final dataRows = hasHeader ? rows.skip(1) : rows;

    debugPrint(
      hasHeader
          ? 'CSV header detected: $headerRow'
          : 'No CSV header detected — using default column mapping',
    );

    int imported = 0;
    int skipped = 0;
    int rowIndex = hasHeader ? 1 : 0;

    for (final rawRow in dataRows) {
      rowIndex++;

      try {
        debugPrint('Processing row $rowIndex: $rawRow');

        final map = <String, String>{};

        for (var i = 0; i < headerRow.length && i < rawRow.length; i++) {
          map[headerRow[i]] = rawRow[i];
        }

        final question = _mapToQuestion(map, defaultSubjID: defaultSubjID);

        if (question == null) {
          skipped++;
          debugPrint('Row $rowIndex skipped: missing required fields');
          continue;
        }

        await _questionRepo.add(question);
        imported++;

        debugPrint('Row $rowIndex imported');
      } catch (e, stack) {
        skipped++;
        debugPrint('ERROR importing row $rowIndex: $e');
        debugPrint(stack.toString());
      }
    }

    debugPrint('CSV IMPORT SUMMARY');
    debugPrint('Imported: $imported');
    debugPrint('Skipped: $skipped');
    debugPrint(
      imported > 0
          ? 'CSV import completed successfully'
          : 'CSV import completed with no valid rows',
    );
  }

  /// Import CSV from a local file path.
  Future<void> importCsvFile(String path, {int defaultSubjID = 1}) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        debugPrint('CSV import aborted: file not found: $path');
        return;
      }

      final normalized = await normalizeCsvFile(path);
      if (normalized.trim().isEmpty) {
        debugPrint(
          'CSV import aborted: file is empty after normalization: $path',
        );
        return;
      }

      await importCsvString(normalized, defaultSubjID: defaultSubjID);
    } catch (e, stack) {
      debugPrint('ERROR reading CSV file: $e');
      debugPrint(stack.toString());
    }
  }

  Question? _mapToQuestion(
    Map<String, String> row, {
    required int defaultSubjID,
  }) {
    final subjID = int.tryParse(row['subjid'] ?? '') ?? defaultSubjID;
    final questionText = (row['questiontext'] ?? '').trim();
    final option1 = (row['option1'] ?? '').trim();
    final option2 = (row['option2'] ?? '').trim();
    final option3 = (row['option3'] ?? '').trim();
    final option4 = (row['option4'] ?? '').trim();
    final correctAnswer = (row['correctanswer'] ?? '').trim();

    if (questionText.isEmpty ||
        option1.isEmpty ||
        option2.isEmpty ||
        option3.isEmpty ||
        option4.isEmpty ||
        correctAnswer.isEmpty) {
      debugPrint('Invalid question data: $row');
      return null;
    }

    return Question(
      subjID: subjID,
      questionText: questionText,
      option1: option1,
      option2: option2,
      option3: option3,
      option4: option4,
      correctAnswer: correctAnswer,
      correctExplanation: row['correctexplanation']?.trim(),
      difficulty: row['difficulty']?.trim().isEmpty ?? true
          ? null
          : row['difficulty']?.trim(),
    );
  }
}
