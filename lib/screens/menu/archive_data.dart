import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../repositories/user_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/question_repository.dart';

class ArchiveDataScreen extends StatefulWidget {
  const ArchiveDataScreen({super.key});

  @override
  State<ArchiveDataScreen> createState() => _ArchiveDataScreenState();
}

class _ArchiveDataScreenState extends State<ArchiveDataScreen> {
  final _userRepo = UserRepository();
  final _progressRepo = ProgressRepository();
  final _questionRepo = QuestionRepository();
  late Future<List<String>> _future;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _buildCsvRows();
  }

  Future<List<String>> _buildCsvRows() async {
    final users = await _userRepo.getAll();
    final subjects = await _questionRepo.getSubjects();

    // Header: User, <Subject>-Easy, <Subject>-Medium, <Subject>-Hard, ...
    final headers = <String>['User'];
    for (final s in subjects) {
      final name = s['subjName'] as String;
      headers.addAll(['$name-Easy', '$name-Medium', '$name-Hard']);
    }

    final rows = <String>[];
    rows.add(headers.join(','));

    final nonAdmin = users.where((u) => u.isAdmin != true).toList();

    for (final u in nonAdmin) {
      final prog = await _progressRepo.getByProfile(u.profileID!);

      // cumulative per subject/difficulty across all rows
      final Map<int, Map<String, int>> subjDiff = {};
      for (final r in prog) {
        subjDiff.putIfAbsent(
          r.subjID,
          () => {'Easy': 0, 'Medium': 0, 'Hard': 0},
        );
        final diff = r.difficulty ?? 'Easy';
        subjDiff[r.subjID]![diff] = (subjDiff[r.subjID]![diff] ?? 0) + r.points;
      }

      final cols = <String>[u.name];
      for (final s in subjects) {
        final id = s['subjID'] as int;
        final map = subjDiff[id];
        cols.add((map == null ? 0 : map['Easy'] ?? 0).toString());
        cols.add((map == null ? 0 : map['Medium'] ?? 0).toString());
        cols.add((map == null ? 0 : map['Hard'] ?? 0).toString());
      }

      rows.add(cols.join(','));
    }

    return rows;
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdk = androidInfo.version.sdkInt;

      if (sdk >= 30) {
        final status = await Permission.manageExternalStorage.status;
        if (status.isGranted) return true;

        final result = await Permission.manageExternalStorage.request();
        if (result.isGranted) return true;

        if (result.isPermanentlyDenied) await openAppSettings();
        return false;
      } else {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
    } catch (e) {
      return false;
    }
  }

  Future<String?> _askFileName(String initial) async {
    final controller = TextEditingController(text: initial);

    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Filename'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCsv(List<String> rows, String suggestedName) async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      // Android permission
      if (Platform.isAndroid) {
        final granted = await _ensureStoragePermission();
        if (!granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
          return;
        }
      }

      final dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null || !mounted) return;

      final filename = await _askFileName(suggestedName);
      if (!mounted || filename == null || filename.isEmpty) return;

      final name =
          filename.toLowerCase().endsWith('.csv') ? filename : '$filename.csv';
      final file = File('$dirPath/$name');
      final csv = rows.join('\n');
      await file.writeAsString(csv, flush: true, encoding: utf8);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving file: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archive Learner Progress')),
      body: FutureBuilder<List<String>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Failed to load archive: ${snap.error}'));
          }

          final rows = snap.data ?? [];
          if (rows.isEmpty) return const Center(child: Text('No data'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 12),
              const Text(
                'This will generate a CSV file containing cumulative points per subject and difficulty for each learner.',
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        await _saveCsv(rows, 'archive-learner-progress');
                      },
                icon: const Icon(Icons.download),
                label: Text('Download CSV'),
              ),
            ],
          );
        },
      ),
    );
  }
}
