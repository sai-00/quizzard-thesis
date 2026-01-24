import 'package:flutter/material.dart';
import 'subject_content.dart' as sc;
import 'play_button.dart';

class SubjectCard extends StatelessWidget {
  final int subjID;
  final String subjName;
  final int profileId;
  const SubjectCard({
    super.key,
    required this.subjID,
    required this.subjName,
    required this.profileId,
  });

  @override
  Widget build(BuildContext context) {
    final image = _coverForSubject(subjName.toLowerCase());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => sc.SubjectContent(
                subjID: subjID,
                subjName: subjName,
                profileId: profileId,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject image
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ExcludeSemantics(
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[300]),
                  ),
                ),
              ),
              // Colored info area with increased padding (1.5x)
              Container(
                color: _subjectColor(subjName.toLowerCase()),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 20.0,
                ),
                child: Column(
                  children: [
                    Text(
                      subjName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: PlayButton(
                        onPlay: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => sc.SubjectContent(
                              subjID: subjID,
                              subjName: subjName,
                              profileId: profileId,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _coverForSubject(String subj) {
    switch (subj) {
      case 'math':
        return 'assets/art/covers/math_cover.png';
      case 'reading':
      case 'eng':
        return 'assets/art/covers/eng_cover.png';
      case 'science':
      case 'sci':
        return 'assets/art/covers/sci_cover.png';
      default:
        return 'assets/art/covers/math_cover.png';
    }
  }

  Color _subjectColor(String subj) {
    switch (subj) {
      case 'math':
        return const Color.fromARGB(255, 16, 48, 53);
      case 'reading':
      case 'eng':
        return const Color.fromARGB(255, 37, 13, 53);
      case 'science':
      case 'sci':
        return const Color.fromARGB(255, 46, 10, 10);
      default:
        return Colors.black87;
    }
  }
}
