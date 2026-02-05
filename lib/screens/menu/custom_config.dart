import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../db/quizzard_db.dart';

class CustomConfigScreen extends StatefulWidget {
  // ignore: use_super_parameters
  const CustomConfigScreen({Key? key}) : super(key: key);

  @override
  State<CustomConfigScreen> createState() => _CustomConfigScreenState();
}

class _CustomConfigScreenState extends State<CustomConfigScreen> {
  bool _working = false;
  bool _stockDisabled = false;

  final List<String> _subjects = ['math', 'reading', 'science'];
  final List<String> _difficulties = ['easy', 'medium', 'hard'];

  @override
  void initState() {
    super.initState();
    _checkStockSuppressed();
  }

  Future<void> _confirmAndDeleteQuestions() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Questions'),
        content: const Text(
          'This will delete ALL questions from the database. Continue?',
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
      final db = await QuizzardDb.instance.db;

      final before =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM questionList'),
          ) ??
          0;

      await db.transaction((txn) async {
        await txn.delete('questionList');
        await txn.execute(
          "DELETE FROM sqlite_sequence WHERE name IN ('questionList');",
        );
      });

      final after =
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM questionList'),
          ) ??
          0;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $before questions. Remaining: $after')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting questions: $e')));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _checkStockSuppressed() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      var allExist = true;
      for (final s in _subjects) {
        for (final d in _difficulties) {
          final f = File(p.join(docs.path, 'custom', s, '${s}_$d.csv'));
          if (!await f.exists()) {
            allExist = false;
            break;
          }
          final content = await f.readAsString();
          if (!content.toLowerCase().contains('suppress_stock')) {
            allExist = false;
            break;
          }
        }
        if (!allExist) break;
      }
      if (mounted) setState(() => _stockDisabled = allExist);
    } catch (e) {
      if (mounted) setState(() => _stockDisabled = false);
    }
  }

  Future<void> _confirmToggleStockSuppression() async {
    final enabling =
        !_stockDisabled; // if currently disabled, we will enable (i.e., create suppress files)

    final title = enabling
        ? 'Disable Stock Cutscenes'
        : 'Enable Stock Cutscenes';
    final content = enabling
        ? 'This will create override files that disable bundled (stock) cutscenes. Continue?'
        : 'This will remove the overrides and restore bundled (stock) cutscenes. Continue?';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(enabling ? 'Disable' : 'Enable'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _working = true);
    try {
      final docs = await getApplicationDocumentsDirectory();

      for (final s in _subjects) {
        final dir = Directory(p.join(docs.path, 'custom', s));
        if (enabling) {
          await dir.create(recursive: true);
          for (final d in _difficulties) {
            final f = File(p.join(dir.path, '${s}_$d.csv'));
            await f.writeAsString('SUPPRESS_STOCK\n');
          }
        } else {
          if (await dir.exists()) {
            for (final d in _difficulties) {
              final f = File(p.join(dir.path, '${s}_$d.csv'));
              if (await f.exists()) await f.delete();
            }
            // if directory empty, attempt to delete it
            try {
              final children = dir.listSync();
              if (children.isEmpty) await dir.delete();
            } catch (_) {}
          }
        }
      }

      await _checkStockSuppressed();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            enabling ? 'Stock cutscenes disabled' : 'Stock cutscenes enabled',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling stock cutscenes: $e')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Configurations')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Delete All Questions'),
            subtitle: const Text('Wipes all questions from the database'),
            enabled: !_working,
            onTap: _working ? null : _confirmAndDeleteQuestions,
          ),
          ListTile(
            leading: const Icon(Icons.movie),
            title: Text(
              _stockDisabled
                  ? 'Enable Stock Cutscenes'
                  : 'Disable Stock Cutscenes',
            ),
            subtitle: Text(
              _stockDisabled
                  ? 'Currently disabled — tap to restore bundled cutscenes'
                  : 'Creates overrides that prevent bundled cutscenes from playing',
            ),
            enabled: !_working,
            onTap: _working ? null : _confirmToggleStockSuppression,
          ),
          if (_working)
            const ListTile(
              title: Text('Working…'),
              subtitle: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
