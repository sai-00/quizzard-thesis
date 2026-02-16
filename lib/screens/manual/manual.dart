
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
	- The CSV will ask for the subject ID and you must input based on this arrangement.
	    - Math       = 1
	    - Reading    = 2
	    - Science    = 3
	- Uploading questions via the CSV upload button will NOT erase the stock questions and will only ADD onto it.
	    - To delete the stock questions, navigate to "Custom Configurations" and select "Delete All Questions". Do note that this will delete the ALL questions AND the game progress.
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

		return Padding(
			padding: const EdgeInsets.all(16.0),
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

