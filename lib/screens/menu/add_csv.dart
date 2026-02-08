import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/csv_sync_service.dart';

class AddCsvScreen extends StatelessWidget {
  const AddCsvScreen({super.key});

  Future<void> _pickFileAndImport(BuildContext context) async {
    final service = CsvSyncService();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return; // user cancelled

      final path = result.files.single.path;
      if (path == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected file has no path')),
          );
        }
        return;
      }

      // Normalize file first (handles Excel exports and encodings) and import from string
      final normalized = await normalizeCsvFile(path);
      await service.importCsvString(normalized);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('CSV imported')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing CSV: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Choose CSV file and Import'),
          onPressed: () => _pickFileAndImport(context),
        ),
      ),
    );
  }
}

class SomeScreen extends StatelessWidget {
  const SomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Some Screen')),
      body: const Center(child: Text('Welcome to Some Screen')),
    );
  }
}
