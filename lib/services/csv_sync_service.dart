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
    if (csvContent.trim().isEmpty) return;
    final rows = _parseCsv(csvContent);
    if (rows.isEmpty) return;

    final headerRow = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    final dataRows = rows.skip(1);

    for (final rawRow in dataRows) {
      try {
        // rawRow is List<String>, elements are non-null Strings — avoid null-aware operator.
        final row = rawRow.map((e) => e.toString()).toList();
        final map = <String, String>{};
        for (var i = 0; i < headerRow.length && i < row.length; i++) {
          map[headerRow[i]] = row[i];
        }

        final q = _mapToQuestion(map, defaultSubjID: defaultSubjID);
        if (q != null) {
          await _questionRepo.add(q);
        }
      } catch (e) {
        // skip malformed row but continue processing others
        debugPrint('CsvSyncService: failed to import row: $e');
      }
    }
  }

  /// Import CSV from a local file path.
  Future<void> importCsvFile(String path, {int defaultSubjID = 1}) async {
    final file = File(path);
    if (!await file.exists()) return;
    final content = await file.readAsString();
    await importCsvString(content, defaultSubjID: defaultSubjID);
  }

  Question? _mapToQuestion(
    Map<String, String> row, {
    required int defaultSubjID,
  }) {
    // helper to map parsed CSV row to Question. Returns null if required fields missing.
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
      difficulty: (row['difficulty']?.trim().isEmpty ?? true)
          ? null
          : row['difficulty']?.trim(),
    );
  }
}
