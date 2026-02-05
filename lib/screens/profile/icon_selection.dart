import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IconSelection extends StatefulWidget {
  const IconSelection({super.key});

  @override
  State<IconSelection> createState() => _IconSelectionState();
}

class _IconSelectionState extends State<IconSelection> {
  late Future<List<String>> _iconsFuture;

  @override
  void initState() {
    super.initState();
    _iconsFuture = _loadIcons();
  }

  Future<List<String>> _loadIcons() async {
    const iconPath = 'assets/icons/';
    const fileNames = [
      'APPLE.png',
      'BANANA.png',
      'ORANGE.png',
      'PINEAPPLE.png',
      'GRAPES.png',
      'EGGPLANT.png',
      'LEMON.png',
      'MANGO.png',
      'STRAWBERRY.png',
      'WATERMELON.png',
    ];

    final List<String> found = [];
    for (final name in fileNames) {
      final path = '$iconPath$name'.replaceFirst('\u007f', '');
      try {
        await rootBundle.load(path);
        found.add(path);
      } catch (_) {
        // ignore missing assets
      }
    }
    found.sort();
    return found;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick an icon'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<String>>(
          future: _iconsFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final icons = snap.data ?? [];
            if (icons.isEmpty) {
              return const Text('No icons available');
            }
            return GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: icons.length,
              itemBuilder: (context, i) {
                final asset = icons[i];
                return InkWell(
                  onTap: () => Navigator.of(context).pop(asset),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(asset),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
