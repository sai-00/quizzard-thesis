import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'; // for debugPrint
import '../models/question.dart';
import '../repositories/question_repository.dart';

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

      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        debugPrint('CSV import aborted: file is empty: $path');
        return;
      }

      await importCsvString(content, defaultSubjID: defaultSubjID);
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
