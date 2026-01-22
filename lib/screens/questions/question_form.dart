import 'package:flutter/material.dart';
import '../../models/question.dart';
import '../../repositories/question_repository.dart';

class QuestionForm extends StatefulWidget {
  final Question? initial;
  const QuestionForm({super.key, this.initial});

  @override
  State<QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  final _form = GlobalKey<FormState>();
  final _repo = QuestionRepository();
  late int subjID;
  late String questionText;
  late TextEditingController _opt1Ctrl;
  late TextEditingController _opt2Ctrl;
  late TextEditingController _opt3Ctrl;
  late TextEditingController _opt4Ctrl;
  late String correctAnswer;
  String? correctExplanation;
  String? difficulty;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    subjID = i?.subjID ?? 1;
    questionText = i?.questionText ?? '';
    _opt1Ctrl = TextEditingController(text: i?.option1 ?? '');
    _opt2Ctrl = TextEditingController(text: i?.option2 ?? '');
    _opt3Ctrl = TextEditingController(text: i?.option3 ?? '');
    _opt4Ctrl = TextEditingController(text: i?.option4 ?? '');
    correctAnswer = i?.correctAnswer ?? '';
    correctExplanation = i?.correctExplanation;
    difficulty = i?.difficulty;
    // keep state in sync as options change
    _opt1Ctrl.addListener(() => setState(() {}));
    _opt2Ctrl.addListener(() => setState(() {}));
    _opt3Ctrl.addListener(() => setState(() {}));
    _opt4Ctrl.addListener(() => setState(() {}));
    // load subjects for dropdown
    QuestionRepository().getSubjects().then((s) {
      if (!mounted) return;
      setState(() => _subjects = s);
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    // pull options from controllers
    final o1 = _opt1Ctrl.text.trim();
    final o2 = _opt2Ctrl.text.trim();
    final o3 = _opt3Ctrl.text.trim();
    final o4 = _opt4Ctrl.text.trim();

    // check duplicate options
    final opts = [o1, o2, o3, o4];
    final unique = opts.toSet();
    if (unique.length != opts.length) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Options must be unique')));
      return;
    }

    final q = Question(
      questionID: widget.initial?.questionID,
      subjID: subjID,
      questionText: questionText,
      option1: o1,
      option2: o2,
      option3: o3,
      option4: o4,
      correctAnswer: correctAnswer,
      correctExplanation: correctExplanation,
      difficulty: difficulty,
    );

    if (widget.initial == null) {
      await _repo.add(q);
    } else {
      await _repo.update(q);
    }
    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final rawOptions = [
      _opt1Ctrl.text.trim(),
      _opt2Ctrl.text.trim(),
      _opt3Ctrl.text.trim(),
      _opt4Ctrl.text.trim(),
    ];
    // count occurrences to detect duplicates and produce a unique ordered list
    final Map<String, int> counts = {};
    for (final o in rawOptions) {
      final t = o.trim();
      if (t.isEmpty) continue;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final availableOptions = counts.keys.toList();
    final duplicates = counts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toList();
    final hasDuplicates = duplicates.isNotEmpty;
    final currentValue = availableOptions.contains(correctAnswer.trim())
        ? correctAnswer.trim()
        : null;
    // build dropdown items from unique options (preserves order)
    final items = availableOptions
        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
        .toList();

    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Question' : 'Edit Question'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subject selector
              DropdownButtonFormField<int>(
                initialValue: subjID,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: _subjects.isNotEmpty
                    ? _subjects
                          .map(
                            (s) => DropdownMenuItem<int>(
                              value: s['subjID'] as int,
                              child: Text(s['subjName'] as String),
                            ),
                          )
                          .toList()
                    : const [
                        DropdownMenuItem<int>(value: 1, child: Text('Math')),
                        DropdownMenuItem<int>(value: 2, child: Text('Science')),
                        DropdownMenuItem<int>(value: 3, child: Text('Reading')),
                      ],
                onChanged: (v) => setState(() => subjID = v ?? subjID),
                validator: (v) => v == null ? 'Select subject' : null,
                onSaved: (v) => subjID = v ?? subjID,
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: questionText,
                decoration: const InputDecoration(labelText: 'Question'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter question' : null,
                onSaved: (v) => questionText = v!.trim(),
              ),
              TextFormField(
                controller: _opt1Ctrl,
                decoration: const InputDecoration(labelText: 'Option 1'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter option' : null,
                onSaved: (v) {},
              ),
              TextFormField(
                controller: _opt2Ctrl,
                decoration: const InputDecoration(labelText: 'Option 2'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter option' : null,
                onSaved: (v) {},
              ),
              TextFormField(
                controller: _opt3Ctrl,
                decoration: const InputDecoration(labelText: 'Option 3'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter option' : null,
                onSaved: (v) {},
              ),
              TextFormField(
                controller: _opt4Ctrl,
                decoration: const InputDecoration(labelText: 'Option 4'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter option' : null,
                onSaved: (v) {},
              ),
              const SizedBox(height: 8),
              if (hasDuplicates)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Duplicate options detected — make all options unique to select a correct answer',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: currentValue,
                decoration: const InputDecoration(labelText: 'Correct Answer'),
                items: items,
                onChanged: hasDuplicates
                    ? null
                    : (v) => setState(() => correctAnswer = v ?? ''),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Select correct answer'
                    : null,
                onSaved: (v) => correctAnswer = v ?? '',
              ),
              TextFormField(
                initialValue: correctExplanation,
                decoration: const InputDecoration(
                  labelText: 'Explanation (required)',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter explanation'
                    : null,
                onSaved: (v) => correctExplanation = v?.trim(),
              ),
              DropdownButtonFormField<String>(
                initialValue: difficulty?.isNotEmpty == true
                    ? difficulty
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Select Difficulty',
                ),
                items: const [
                  DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                ],
                onChanged: (value) {
                  setState(() {
                    difficulty = value;
                  });
                },
                validator: (v) =>
                    v == null ? 'Please select a difficulty' : null,
                onSaved: (v) => difficulty = v,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  @override
  void dispose() {
    _opt1Ctrl.dispose();
    _opt2Ctrl.dispose();
    _opt3Ctrl.dispose();
    _opt4Ctrl.dispose();
    super.dispose();
  }
}
