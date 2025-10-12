import '../db/quizzard_db.dart';
import '../models/progress.dart';

class ProgressRepository {
  final QuizzardDb _db = QuizzardDb.instance;

  Future<List<Progress>> getAll() async {
    final db = await _db.db;
    final rows = await db.query('gameProgress', orderBy: 'datePlayed DESC');
    return rows.map((r) => Progress.fromMap(r)).toList();
  }

  Future<List<Progress>> getByProfile(int profileID) async {
    final db = await _db.db;
    final rows = await db.query(
      'gameProgress',
      where: 'profileID = ?',
      whereArgs: [profileID],
      orderBy: 'datePlayed DESC',
    );
    return rows.map((r) => Progress.fromMap(r)).toList();
  }

  Future<List<Progress>> getByProfileAndRun(int profileID, String runID) async {
    final db = await _db.db;
    final rows = await db.query(
      'gameProgress',
      where: 'profileID = ? AND runID = ?',
      whereArgs: [profileID, runID],
    );
    return rows.map((r) => Progress.fromMap(r)).toList();
  }

  Future<int> add(Progress p) async {
    final db = await _db.db;
    return await db.insert('gameProgress', p.toMap());
  }

  Future<void> addBatch(List<Progress> items) async {
    final db = await _db.db;
    await db.transaction((txn) async {
      for (final p in items) {
        await txn.insert('gameProgress', p.toMap());
      }
    });
  }
}
