import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class QuizzardDb {
  QuizzardDb._privateConstructor();
  static final QuizzardDb instance = QuizzardDb._privateConstructor();

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'gamedb.db');

    // open database with onCreate + onOpen migration checks
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // create schema from asset if available
        try {
          final sql = await rootBundle.loadString('assets/db/gamedb.sql');
          final statements = _splitSql(sql);
          for (final s in statements) {
            final stmt = s.trim();
            if (stmt.isNotEmpty) {
              await db.execute(stmt);
            }
          }
        } catch (e) {
          // fallback: create minimal required tables so app won't completely fail
          await db.execute('PRAGMA foreign_keys = ON;');
          await db.execute(
            'CREATE TABLE IF NOT EXISTS userProfile (profileID INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, avatar TEXT, isAdmin INTEGER DEFAULT 0, adminPasscode TEXT);',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS subject (subjID INTEGER PRIMARY KEY AUTOINCREMENT, subjName TEXT NOT NULL);',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS questionList (questionID INTEGER PRIMARY KEY AUTOINCREMENT, subjID INTEGER NOT NULL, questionText TEXT NOT NULL, option1 TEXT NOT NULL, option2 TEXT NOT NULL, option3 TEXT NOT NULL, option4 TEXT NOT NULL, correctAnswer TEXT NOT NULL);',
          );
          await db.execute(
            'CREATE TABLE IF NOT EXISTS gameProgress (gameProgID INTEGER PRIMARY KEY AUTOINCREMENT, profileID INTEGER NOT NULL, questionID INTEGER NOT NULL);',
          );
        }
      },
      onOpen: (db) async {
        // run lightweight migrations to add any new columns safely
        await _ensureGameProgressColumns(db);
        await _ensureUserProfileColumns(db);
      },
    );

    return database;
  }

  // naive SQL splitter: splits on semicolon. Works for most asset .sql files.
  List<String> _splitSql(String sql) {
    return sql
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  // Check PRAGMA table_info and add missing columns.
  Future<void> _ensureGameProgressColumns(Database db) async {
    try {
      final cols = await db.rawQuery("PRAGMA table_info('gameProgress')");
      final existing = <String>{};
      for (final c in cols) {
        final name = (c['name'] ?? c['column'])?.toString();
        if (name != null) existing.add(name);
      }

      // list of required columns and their ALTER statements (safe defaults)
      final Map<String, String> needed = {
        'subjID':
            'ALTER TABLE gameProgress ADD COLUMN subjID INTEGER DEFAULT 1;',
        'difficulty': "ALTER TABLE gameProgress ADD COLUMN difficulty TEXT;",
        'level': 'ALTER TABLE gameProgress ADD COLUMN level INTEGER;',
        'points':
            'ALTER TABLE gameProgress ADD COLUMN points INTEGER DEFAULT 0;',
        'progressLevel':
            'ALTER TABLE gameProgress ADD COLUMN progressLevel TEXT;',
        'datePlayed': "ALTER TABLE gameProgress ADD COLUMN datePlayed TEXT;",
        'timeOn': "ALTER TABLE gameProgress ADD COLUMN timeOn TEXT;",
        'timeOut': "ALTER TABLE gameProgress ADD COLUMN timeOut TEXT;",
        'runID': "ALTER TABLE gameProgress ADD COLUMN runID TEXT;",
      };

      for (final kv in needed.entries) {
        if (!existing.contains(kv.key)) {
          try {
            await db.execute(kv.value);
          } catch (e) {
            // ignore individual failures but keep trying others
          }
        }
      }
    } catch (e) {
      // if table doesn't exist, do nothing (onCreate should have created it)
    }
  }

  // Ensure `userProfile` has admin-related columns.
  Future<void> _ensureUserProfileColumns(Database db) async {
    try {
      final cols = await db.rawQuery("PRAGMA table_info('userProfile')");
      final existing = <String>{};
      for (final c in cols) {
        final name = (c['name'] ?? c['column'])?.toString();
        if (name != null) existing.add(name);
      }

      final Map<String, String> needed = {
        'isAdmin':
            'ALTER TABLE userProfile ADD COLUMN isAdmin INTEGER DEFAULT 0;',
        'adminPasscode':
            'ALTER TABLE userProfile ADD COLUMN adminPasscode TEXT;',
      };

      for (final kv in needed.entries) {
        if (!existing.contains(kv.key)) {
          try {
            await db.execute(kv.value);
          } catch (e) {
            // ignore individual failures
          }
        }
      }
    } catch (e) {
      // ignore: the table may not yet exist
    }
  }
}
