// ignore_for_file: use_super_parameters

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';

class DownloadCsvScreen extends StatefulWidget {
  const DownloadCsvScreen({Key? key}) : super(key: key);

  @override
  State<DownloadCsvScreen> createState() => _DownloadCsvScreenState();
}

class _DownloadCsvScreenState extends State<DownloadCsvScreen> {
  bool _isSaving = false;

  Future<void> _downloadWithSaveDialog(
    String assetPath,
    String suggestedName,
  ) async {
    setState(() => _isSaving = true);
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      final String? dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null) {
        // user cancelled
        return;
      }

      if (!mounted) return;

      final filename = await _askFileName(context, suggestedName);
      if (filename == null || filename.isEmpty) return;
      final name = filename.toLowerCase().endsWith('.csv')
          ? filename
          : '$filename.csv';

      final file = File('$dirPath/$name');
      await file.writeAsBytes(bytes, flush: true);

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
      setState(() => _isSaving = false);
    }
  }

  Future<String?> _askFileName(BuildContext context, String initial) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String?>(
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
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download CSV templates')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('download questions csv template'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () => _downloadWithSaveDialog(
                    'templates/csv-question.csv',
                    'csv-question.csv',
                  ),
            child: const Text('download'),
          ),
          const SizedBox(height: 24),
          const Text('download cutscene csv template'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () => _downloadWithSaveDialog(
                    'templates/csv-cutscene.csv',
                    'csv-cutscene.csv',
                  ),
            child: const Text('download'),
          ),
        ],
      ),
    );
  }
}
