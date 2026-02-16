import 'package:flutter/material.dart';

class ManualMenu extends StatelessWidget {
  final void Function(String topic) onSelect;
  const ManualMenu({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('How to Use Upload Questions CSV'),
          leading: const Icon(Icons.upload_file),
          onTap: () => onSelect('questions'),
        ),
        ListTile(
          title: const Text('How to Use Upload Cutscenes CSV'),
          leading: const Icon(Icons.movie),
          onTap: () => onSelect('cutscenes'),
        ),
      ],
    );
  }
}
