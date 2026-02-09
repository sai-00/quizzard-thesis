import 'dart:async';
import '../db/quizzard_db.dart';
import '../models/question.dart';

class QuestionRepository {
  final QuizzardDb _db = QuizzardDb.instance;

  Future<List<Question>> getAll() async {
    final database = await _db.db;
    final rows = await database.query('questionList', orderBy: 'questionID');
    return rows.map((r) => Question.fromMap(r)).toList();
  }

  Future<Question?> getById(int id) async {
    final database = await _db.db;
    final rows = await database.query(
      'questionList',
      where: 'questionID = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return Question.fromMap(rows.first);
  }

  Future<int> add(Question q) async {
    final database = await _db.db;
    return await database.insert('questionList', q.toMap());
  }

  Future<int> update(Question q) async {
    final database = await _db.db;
    return await database.update(
      'questionList',
      q.toMap(),
      where: 'questionID = ?',
      whereArgs: [q.questionID],
    );
  }

  Future<int> delete(int id) async {
    final database = await _db.db;
    // remove any dependent progress rows first to avoid FK constraint errors
    try {
      return await database.transaction<int>((txn) async {
        await txn.delete(
          'gameProgress',
          where: 'questionID = ?',
          whereArgs: [id],
        );
        final q = await txn.delete(
          'questionList',
          where: 'questionID = ?',
          whereArgs: [id],
        );
        return q; // return number of questions deleted
      });
    } catch (e) {
      // propagate or return 0 on failure
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getSubjects() async {
    final database = await _db.db;
    return await database.query('subject', orderBy: 'subjID');
  }

  Future<List<Question>> getBySubject(int subjID, {String? difficulty}) async {
    final database = await _db.db;
    final where = <String>['subjID = ?'];
    final args = <dynamic>[subjID];
    if (difficulty != null) {
      where.add('difficulty = ?');
      args.add(difficulty);
    }
    final rows = await database.query(
      'questionList',
      where: where.join(' AND '),
      whereArgs: args,
    );
    return rows.map((r) => Question.fromMap(r)).toList();
  }
}
