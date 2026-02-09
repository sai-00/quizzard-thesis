// ignore_for_file: use_super_parameters

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../db/quizzard_db.dart';

class ResetConfigScreen extends StatefulWidget {
  const ResetConfigScreen({Key? key}) : super(key: key);

  @override
  State<ResetConfigScreen> createState() => _ResetConfigScreenState();
}

class _ResetConfigScreenState extends State<ResetConfigScreen> {
  bool _working = false;

  Future<void> _confirmAndResetQuestions() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Questions'),
        content: const Text(
          'This will wipe all questions and restore stock questions. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _working = true);

    try {
      final db = await QuizzardDb.instance.db;

      // Use a transaction and disable foreign keys to ensure resets succeed
      await db.transaction((txn) async {
        await txn.execute('PRAGMA foreign_keys = OFF;');

        await txn.delete('gameProgress');
        await txn.delete('questionList');
        await txn.delete('subject');

        await txn.execute(
          "DELETE FROM sqlite_sequence WHERE name IN ('subject','questionList');",
        );

        await txn.execute("""
          INSERT INTO subject (subjName) VALUES
          ('Math'),
          ('Reading'),
          ('Science');
        """);

        final sql = await rootBundle.loadString('assets/db/gamedb.sql');
        final statements = QuizzardDb.instance.splitSql(sql);

        for (final stmt in statements) {
          final lower = stmt.toLowerCase();
          if (lower.contains('insert into questionlist')) {
            await txn.execute(stmt);
          }
        }

        await txn.execute('PRAGMA foreign_keys = ON;');
      });

      final qCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM questionList'),
          ) ??
          0;

      final sCount =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM subject'),
          ) ??
          0;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset complete — $qCount questions, $sCount subjects'),
        ),
      );
    } catch (e, st) {
      debugPrint('Reset failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error resetting questions: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirmAndResetCustomCutscenes() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Custom Cutscenes'),
        content: const Text(
          'This will delete all uploaded custom cutscene CSVs. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _working = true);
    try {
      final docs = await getApplicationDocumentsDirectory();
      final customDir = Directory(p.join(docs.path, 'custom'));
      if (await customDir.exists()) {
        await customDir.delete(recursive: true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom cutscenes deleted')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No custom cutscenes found')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting custom cutscenes: $e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Configurations')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Reset Questions'),
            subtitle: const Text(
              'Wipes questions and restores stock questions',
            ),
            enabled: !_working,
            onTap: _working ? null : _confirmAndResetQuestions,
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Reset Custom Cutscenes'),
            subtitle: const Text('Deletes uploaded custom cutscene CSVs'),
            enabled: !_working,
            onTap: _working ? null : _confirmAndResetCustomCutscenes,
          ),
        ],
      ),
    );
  }
}
