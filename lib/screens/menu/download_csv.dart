// ignore_for_file: use_super_parameters

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadCsvScreen extends StatefulWidget {
  const DownloadCsvScreen({Key? key}) : super(key: key);

  @override
  State<DownloadCsvScreen> createState() => _DownloadCsvScreenState();
}

class _DownloadCsvScreenState extends State<DownloadCsvScreen> {
  bool _isSaving = false;

  /// Main function to save an asset CSV
  Future<void> _downloadCsv(String assetPath, String suggestedName) async {
    if (!mounted) return; // early exit just in case
    setState(() => _isSaving = true);

    try {
      // Load bytes from assets
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();

      String? dirPath;

      // Android storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
          return;
        }
      }

      // Ask user for directory
      dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null || !mounted) return;

      // Ask for filename
      final filename = await _askFileName(suggestedName);
      if (!mounted || filename == null || filename.isEmpty) return;

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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<String?> _askFileName(String initial) async {
    final controller = TextEditingController(text: initial);

    return showDialog<String?>(
      context: context, // safe here, synchronous
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Download CSV templates')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Download questions CSV template'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () => _downloadCsv(
                    'templates/csv-question.csv',
                    'csv-question',
                  ),
            child: const Text('Download'),
          ),
          const SizedBox(height: 24),
          const Text('Download cutscene CSV template'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () => _downloadCsv(
                    'templates/csv-cutscene.csv',
                    'csv-cutscene',
                  ),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
