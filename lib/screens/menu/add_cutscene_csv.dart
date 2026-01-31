// ignore_for_file: use_super_parameters

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class AddCutsceneCsvScreen extends StatefulWidget {
  const AddCutsceneCsvScreen({Key? key}) : super(key: key);

  @override
  State<AddCutsceneCsvScreen> createState() => _AddCutsceneCsvScreenState();
}

class _AddCutsceneCsvScreenState extends State<AddCutsceneCsvScreen> {
  final List<String> _subjects = ['science', 'math', 'reading'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  String? _selectedSubject;
  bool _isUploading = false;

  Future<void> _uploadFor(String subject, String difficulty) async {
    setState(() => _isUploading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );
      if (result == null) return; // user cancelled

      final pickedPath = result.files.single.path;
      if (pickedPath == null) return;

      final bytes = await File(pickedPath).readAsBytes();

      // Save into the app documents directory under `custom/<subject>/`.
      final docDir = await getApplicationDocumentsDirectory();
      final targetDir =
          '${docDir.path}${Platform.pathSeparator}custom${Platform.pathSeparator}$subject';

      final dir = Directory(targetDir);
      if (!await dir.exists()) await dir.create(recursive: true);

      final filename =
          '${subject.toLowerCase()}_${difficulty.toLowerCase()}.csv';
      final dest = File('${dir.path}${Platform.pathSeparator}$filename');
      await dest.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved to ${dest.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Cutscenes CSV'),
        leading: _selectedSubject == null
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedSubject = null),
              ),
      ),
      body: _selectedSubject == null ? _buildSubjectList() : _buildUploadView(),
    );
  }

  Widget _buildSubjectList() {
    return ListView.builder(
      itemCount: _subjects.length,
      itemBuilder: (context, i) {
        final sub = _subjects[i];
        return ListTile(
          leading: const Icon(Icons.book),
          title: Text(sub[0].toUpperCase() + sub.substring(1)),
          onTap: () => setState(() => _selectedSubject = sub),
        );
      },
    );
  }

  Widget _buildUploadView() {
    final subjectDisplay =
        _selectedSubject![0].toUpperCase() + _selectedSubject!.substring(1);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final diff in _difficulties) ...[
          Text(
            '$subjectDisplay ${diff.toLowerCase()} difficulty cutscenes file',
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isUploading
                ? null
                : () => _uploadFor(_selectedSubject!, diff),
            child: const Text('Upload'),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
