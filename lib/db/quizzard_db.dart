import 'dart:async';
import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class QuizzardDb {
  QuizzardDb._privateConstructor();
  static final QuizzardDb instance = QuizzardDb._privateConstructor();

  Database? _db;

  // Resolve a portable database path.
  // On desktop platforms attempt to use an executable-relative file so the
  // app can be distributed as a portable ZIP. If that location isn't
  // writable, fall back to the normal `getDatabasesPath()` provided by
  // the `sqflite` package (which is platform-appropriate).
  Future<String> _resolveDbPath() async {
    if (kIsWeb) {
      throw UnsupportedError('sqflite is not supported on the web');
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final candidate = p.join(exeDir, 'gamedb.db');
        final file = File(candidate);
        if (await file.exists()) return candidate;

        // Try creating the file to verify writability. If creation fails,
        // we'll fall back to the default databases path.
        await file.create(recursive: true);
        // leave the file empty; onCreate will populate the schema
        return candidate;
      } catch (_) {
        // ignore and fallback
      }
    }

    final databasesPath = await getDatabasesPath();
    return p.join(databasesPath, 'gamedb.db');
  }

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = await _resolveDbPath();

    // open database with onCreate + onOpen migration checks
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // create schema from asset if available
        try {
          final sql = await rootBundle.loadString('assets/db/gamedb.sql');
          final statements = splitSql(sql);
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

  // Robust SQL splitter: splits on semicolons that are not inside single-quoted
  // string literals. Handles doubled single-quotes used to escape a quote
  // inside a literal (SQL: ''). Returns statements without the trailing
  // semicolon and ignores empty statements.
  List<String> splitSql(String sql) {
    final List<String> out = [];
    final sb = StringBuffer();
    bool inQuote = false;
    for (int i = 0; i < sql.length; i++) {
      final ch = sql[i];
      if (ch == "'") {
        // detect doubled single-quote (escaped quote) -- consume both and
        // keep them inside the buffer
        if (i + 1 < sql.length && sql[i + 1] == "'") {
          sb.write("''");
          i++; // skip the escaped quote
          continue;
        }
        inQuote = !inQuote;
        sb.write(ch);
        continue;
      }
      if (ch == ';' && !inQuote) {
        final stmt = sb.toString().trim();
        if (stmt.isNotEmpty) out.add(stmt);
        sb.clear();
        continue;
      }
      sb.write(ch);
    }
    final last = sb.toString().trim();
    if (last.isNotEmpty) out.add(last);
    return out;
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
