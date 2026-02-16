import 'package:flutter/material.dart';

import 'manual_menu.dart';
import 'manual.dart';

class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  String? _selectedTopic;

  void _onSelect(String topic) => setState(() => _selectedTopic = topic);

  void _backToMenu() => setState(() => _selectedTopic = null);

  @override
  Widget build(BuildContext context) {
    final Widget body = _selectedTopic == null
        ? ManualMenu(onSelect: _onSelect)
        : ManualContent(topic: _selectedTopic!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Manual'),
        leading: _selectedTopic != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToMenu,
              )
            : null,
      ),
      body: body,
    );
  }
}
