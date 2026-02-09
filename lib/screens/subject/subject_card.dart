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
    final subjectColor = _subjectColor(subjName.toLowerCase());

    void navigate() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => sc.SubjectContent(
            subjID: subjID,
            subjName: subjName,
            profileId: profileId,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
      child: Card(
        clipBehavior: Clip.hardEdge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: InkWell(
          onTap: navigate,
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

              // Colored info area WITH shine overlay
              ClipRect(
                child: Container(
                  color: subjectColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18.0,
                    vertical: 20.0,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(painter: _ShinePainter()),
                        ),
                      ),

                      // Actual content
                      Column(
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
                            child: PlayButton(onPlay: navigate),
                          ),
                        ],
                      ),
                    ],
                  ),
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
        return const Color.fromARGB(255, 66, 12, 12);
      default:
        return Colors.black87;
    }
  }
}

class _ShinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final whitePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final blackPaint = Paint()
      ..color = Colors.black.withOpacity(0.13)
      ..style = PaintingStyle.fill;

    final double slant = size.height * 0.65;

    Path stripe({required double startX, required double width}) {
      return Path()
        ..moveTo(startX, -slant)
        ..lineTo(startX + width, -slant)
        ..lineTo(startX + width - slant, size.height + slant)
        ..lineTo(startX - slant, size.height + slant)
        ..close();
    }

    final double pair1Start = size.width * 0.14;

    canvas.drawPath(stripe(startX: pair1Start, width: 25), blackPaint);

    canvas.drawPath(stripe(startX: pair1Start + 25, width: 64), whitePaint);

    final double gap = 164;

    final double pair2Start = pair1Start + 12 + 22 + gap;

    canvas.drawPath(stripe(startX: pair2Start, width: 20), blackPaint);

    canvas.drawPath(stripe(startX: pair2Start + 20, width: 45), whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
