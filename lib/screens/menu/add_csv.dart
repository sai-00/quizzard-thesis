import 'package:flutter/material.dart';
import '../../services/csv_sync_service.dart';

// Simple CSV paste/import UI to avoid requiring file_picker package.
class AddCsvScreen extends StatelessWidget {
  const AddCsvScreen({super.key});

  Future<void> _showPasteDialog(BuildContext context) async {
    final controller = TextEditingController();
    final service = CsvSyncService(); // ensure the service class is referenced

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paste CSV content'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 12,
            decoration: const InputDecoration(hintText: 'Paste CSV here'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.trim().isNotEmpty) {
      await service.importCsvString(controller.text);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('CSV imported')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import CSV')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Paste CSV and Import'),
          onPressed: () => _showPasteDialog(context),
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
