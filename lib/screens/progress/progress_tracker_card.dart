import 'package:flutter/material.dart';

class ProgressTrackerCard extends StatefulWidget {
  final String subjectName;
  final Map<String, int> difficultyPoints; // Easy/Medium/Hard
  final List<Map<String, dynamic>> sessions; // list of {datePlayed, points}
  const ProgressTrackerCard({
    super.key,
    required this.subjectName,
    required this.difficultyPoints,
    required this.sessions,
  });

  @override
  State<ProgressTrackerCard> createState() => _ProgressTrackerCardState();
}

class _ProgressTrackerCardState extends State<ProgressTrackerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.subjectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _badge(
                  'easy',
                  widget.difficultyPoints['Easy'] ?? 0,
                  Colors.green,
                ),
                const SizedBox(width: 8),
                _badge(
                  'medium',
                  widget.difficultyPoints['Medium'] ?? 0,
                  Colors.orange,
                ),
                const SizedBox(width: 8),
                _badge(
                  'hard',
                  widget.difficultyPoints['Hard'] ?? 0,
                  Colors.red,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(),
              ..._buildSessionWidgets(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSessionWidgets() {
    if (widget.sessions.isEmpty) {
      return [const Text('No sessions')];
    }
    final rows = <Widget>[];
    final show = widget.sessions.take(3);
    for (final s in show) {
      final raw = s['datePlayed'] as String?;
      final pts = s['points'] as int? ?? 0;
      rows.add(Text('Date played : ${_formatDateTime(raw)}'));
      rows.add(const SizedBox(height: 4));
      rows.add(Text('Accumulated points for session : $pts'));
      rows.add(const SizedBox(height: 8));
    }
    return rows;
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
