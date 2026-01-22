import 'package:flutter/material.dart';
import '../../repositories/question_repository.dart';
import '../../models/question.dart';
import 'question_card.dart';
import 'question_form.dart';

class QuestionCrudScreen extends StatefulWidget {
  const QuestionCrudScreen({super.key});
  @override
  State<QuestionCrudScreen> createState() => _QuestionCrudScreenState();
}

class _QuestionCrudScreenState extends State<QuestionCrudScreen> {
  final _repo = QuestionRepository();
  late Future<List<Question>> _future;
  List<Question> _all = [];
  List<Question> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();
  int? _selectedSubjID;
  String? _selectedDifficulty;
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilters);
    // load subjects for dropdown (one-time)
    QuestionRepository().getSubjects().then((s) {
      if (!mounted) return;
      setState(() => _subjects = s);
    });
  }

  void _load() {
    _future = _repo.getAll();
    _future.then((list) {
      if (!mounted) return;
      setState(() {
        _all = list;
        _filtered = List<Question>.from(_all);
      });
    });
  }

  Future<void> _openForm({Question? initial}) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => QuestionForm(initial: initial),
    );
    if (res == true) {
      _load();
    }
  }

  Future<void> _deleteQuestion(int id) async {
    final ok = await _repo.delete(id);

    final success = (ok as dynamic) == true || ok == 1;

    if (success) {
      if (!mounted) return;
      // refresh list but stay on this screen
      _load();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question deleted')));
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((item) {
        if (q.isNotEmpty && !item.questionText.toLowerCase().contains(q)) {
          return false;
        }
        if (_selectedSubjID != null && item.subjID != _selectedSubjID) {
          return false;
        }
        if (_selectedDifficulty != null &&
            item.difficulty != _selectedDifficulty) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Question Manager')),
      body: FutureBuilder<List<Question>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // build search and filters UI above the list
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search question here',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                // Filters: subject and difficulty
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<int?>(
                        value: _selectedSubjID,
                        isExpanded: true,
                        hint: const Text('Select Subject'),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All Subjects'),
                          ),
                          ..._subjects.map(
                            (s) => DropdownMenuItem<int?>(
                              value: s['subjID'] as int,
                              child: Text(s['subjName'] as String),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedSubjID = v);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButton<String?>(
                              value: _selectedDifficulty,
                              isExpanded: true,
                              hint: const Text('Select Difficulty'),
                              items: const [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All Difficulties'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Easy',
                                  child: Text('Easy'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Medium',
                                  child: Text('Medium'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'Hard',
                                  child: Text('Hard'),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() => _selectedDifficulty = v);
                                _applyFilters();
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchCtrl.clear();
                                _selectedSubjID = null;
                                _selectedDifficulty = null;
                                _filtered = List<Question>.from(_all);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('No questions'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => QuestionCard(
                            question: _filtered[i],
                            onEdit: () => _openForm(initial: _filtered[i]),
                            onDelete: () =>
                                _deleteQuestion(_filtered[i].questionID!),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _openForm(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
