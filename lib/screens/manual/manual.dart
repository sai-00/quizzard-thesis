import 'package:flutter/material.dart';

class ManualContent extends StatelessWidget {
  final String topic;
  const ManualContent({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    String title;
    String content;

    if (topic == 'questions') {
      title = 'Upload Questions CSV';
      content = '''For Uploading Questions Via CSV:

      1. Navigate to the "Download CSV Templates".
      2. Download the Questions template.
      3. Fill it up accordingly.
      4. Navigate to the "Upload Questions CSV".
      5. Upload the file.

      Important things to take note of:
      - Be sure to wrap the question text, answer options, correct answer, correct explanation and difficulty with quotation marks, otherwise the CSV will not be able to read it properly.
      - The correct answer column should contain the EXACT text of the answer option.
      - The CSV will ask for the subject ID and you must input based on this arrangement.
          - Math       = 1
          - Reading    = 2
          - Science    = 3
      - The CSV will ask for the difficulty and you must input based on this arrangement.
          - Easy       = Easy
          - Medium     = Medium
          - Hard       = Hard
      - Uploading questions via the CSV upload button will NOT erase the stock questions and will only ADD onto it.
          - To delete the stock questions, navigate to "Custom Configurations" and select "Delete All Questions". Do note that this will delete ALL questions AND the game progress.
          - To restore the stock questions, navigate to "Reset Configurations" and select "Reset Questions". Do note that this will delete ALL CUSTOM questions.
      ''';
    } else if (topic == 'cutscenes') {
      title = 'Upload Cutscenes CSV';
      content = '''For Uploading Custom Cutscenes Via CSV:

      1. Navigate to the "Download CSV Templates".
      2. Download the Cutscenes template.
      3. Fill it up accordingly.
      4. Navigate to the "Upload Cutscenes CSV".
      5. Navigate to chosen subject and difficulty.
      6. Upload the file.

      Important things to take note of:
      - Be sure to wrap the dialogue (and only the dialogue) with quotation marks, otherwise the CSV will not be able to read it properly.
      - The CSV will ask for the "level" and you must input based on this arrangement.
          - Level 1       = 1
          - Level 2       = 2
          - Level 3       = 3
          - Level 4       = 4
          - Level 5       = 5
          - Final Level   = 99
      - The CSV will ask for the "sprite state" and you must input based on this arrangement.
          - Talking       = talking
          - Happy         = correct
          - Doubt         = wrong
      - The "placement" column is for you to decide whether the cutscene will appear at the beginning or at the end of the level.
      - The "order" column is for you to decide the order of the lines within a cutscene.
      - Each subject and each difficulty of a subject has its own CSV file. Each CSV file will contain all the cutscenes in one difficulty.
      - Every time a new file will be uploaded, it will overwrite the previous file you have uploaded prior.
      - To restore back the stock cutscenes and delete the custom ones, navigate to "Reset Configurations" and select "Reset Custom Cutscenes".
      - To completely turn off cutscenes, navigate to "Custom Configurations" and select "Disable Stock Cutscenes"
      - If you only wish to have blank cutscenes per specific subject/difficulty, you may just add a blank copy of the CSV file.
      ''';
    } else {
      title = 'Manual';
      content = 'Select a topic from the menu.';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
