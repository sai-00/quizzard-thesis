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
  late String option1;
  late String option2;
  late String option3;
  late String option4;
  late String correctAnswer;
  String? correctExplanation;
  String? difficulty;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    subjID = i?.subjID ?? 1;
    questionText = i?.questionText ?? '';
    option1 = i?.option1 ?? '';
    option2 = i?.option2 ?? '';
    option3 = i?.option3 ?? '';
    option4 = i?.option4 ?? '';
    correctAnswer = i?.correctAnswer ?? '';
    correctExplanation = i?.correctExplanation;
    difficulty = i?.difficulty;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    _form.currentState!.save();

    final q = Question(
      questionID: widget.initial?.questionID,
      subjID: subjID,
      questionText: questionText,
      option1: option1,
      option2: option2,
      option3: option3,
      option4: option4,
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
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Question' : 'Edit Question'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: questionText,
                decoration: const InputDecoration(labelText: 'Question'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter question' : null,
                onSaved: (v) => questionText = v!.trim(),
              ),
              TextFormField(
                initialValue: option1,
                decoration: const InputDecoration(labelText: 'Option 1'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter option' : null,
                onSaved: (v) => option1 = v!.trim(),
              ),
              TextFormField(
                initialValue: option2,
                decoration: const InputDecoration(labelText: 'Option 2'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter option' : null,
                onSaved: (v) => option2 = v!.trim(),
              ),
              TextFormField(
                initialValue: option3,
                decoration: const InputDecoration(labelText: 'Option 3'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter option' : null,
                onSaved: (v) => option3 = v!.trim(),
              ),
              TextFormField(
                initialValue: option4,
                decoration: const InputDecoration(labelText: 'Option 4'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter option' : null,
                onSaved: (v) => option4 = v!.trim(),
              ),
              TextFormField(
                initialValue: correctAnswer,
                decoration: const InputDecoration(
                  labelText: 'Correct Answer (exact text)',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter correct answer'
                    : null,
                onSaved: (v) => correctAnswer = v!.trim(),
              ),
              TextFormField(
                initialValue: correctExplanation,
                decoration: const InputDecoration(
                  labelText: 'Explanation (optional)',
                ),
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
}
