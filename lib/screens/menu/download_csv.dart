// ignore_for_file: use_super_parameters

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

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

      // Android storage permission (use MANAGE_EXTERNAL_STORAGE on Android 11+/SDK 30+)
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

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdk = androidInfo.version.sdkInt;

      if (sdk >= 30) {
        // Android 11+ requires MANAGE_EXTERNAL_STORAGE for broad file access
        final status = await Permission.manageExternalStorage.status;
        if (status.isGranted) return true;

        final result = await Permission.manageExternalStorage.request();
        if (result.isGranted) return true;

        if (result.isPermanentlyDenied) {
          // Open app settings to let user grant "All files access"
          await openAppSettings();
        }
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
