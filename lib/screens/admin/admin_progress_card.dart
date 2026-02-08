import 'package:flutter/material.dart';
import '../../models/user.dart';

class AdminProgressCard extends StatelessWidget {
  final User user;
  final String? latestDate;
  final int latestSessionPoints;
  final Map<int, Map<String, int>>
  subjDifficultyPoints; // subjID -> {difficulty: points}
  final Map<int, String> subjectNames;

  const AdminProgressCard({
    super.key,
    required this.user,
    required this.latestDate,
    required this.latestSessionPoints,
    required this.subjDifficultyPoints,
    required this.subjectNames,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Date played : ${_formatDateTime(latestDate)}'),
            const SizedBox(height: 6),
            Text(
              'Accumulated points for latest session : $latestSessionPoints',
            ),
            const Divider(),
            ..._buildSubjectRows(),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year.toString();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$d-$m-$y $hh:$mm';
    } catch (_) {
      return raw;
    }
  }

  List<Widget> _buildSubjectRows() {
    final rows = <Widget>[];
    subjDifficultyPoints.forEach((subjID, diffMap) {
      final name = subjectNames[subjID] ?? 'Subject $subjID';
      rows.add(
        Text('$name :', style: const TextStyle(fontWeight: FontWeight.w600)),
      );
      rows.add(const SizedBox(height: 6));
      rows.add(
        Row(
          children: [
            _badge('easy', diffMap['Easy'] ?? 0, Colors.green),
            const SizedBox(width: 8),
            _badge('medium', diffMap['Medium'] ?? 0, Colors.orange),
            const SizedBox(width: 8),
            _badge('hard', diffMap['Hard'] ?? 0, Colors.red),
          ],
        ),
      );
      rows.add(const SizedBox(height: 10));
    });
    return rows;
  }

  Widget _badge(String label, int pts, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha((0.12 * 255).round()),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Text(label),
        const SizedBox(width: 6),
        Text(
          pts.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
