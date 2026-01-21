import 'dart:async';
import '../db/quizzard_db.dart';
import '../models/user.dart';

class UserRepository {
  final QuizzardDb _db = QuizzardDb.instance;

  Future<List<User>> getAll() async {
    final database = await _db.db;
    final rows = await database.query('userProfile', orderBy: 'profileID');
    return rows.map((r) => User.fromMap(r)).toList();
  }

  Future<int> add(User user) async {
    final database = await _db.db;
    return await database.insert('userProfile', user.toMap());
  }

  Future<int> delete(int profileID) async {
    final database = await _db.db;
    return await database.delete(
      'userProfile',
      where: 'profileID = ?',
      whereArgs: [profileID],
    );
  }

  Future<int> update(User user) async {
    final database = await _db.db;
    return await database.update(
      'userProfile',
      user.toMap(),
      where: 'profileID = ?',
      whereArgs: [user.profileID],
    );
  }
}
