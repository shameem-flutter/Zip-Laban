import 'package:flutter/material.dart';

class DailySnapshotCurvePainter extends CustomPainter {
  final Color lineColor;
  final Color dotColor;

  DailySnapshotCurvePainter({
    this.lineColor = const Color(0xFF1E60F2),
    this.dotColor = const Color(0xFF1E60F2),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Background gradient for upper card atmosphere
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFE2EDFD).withValues(alpha: 0.7),
        const Color(0xFFF0F6FF).withValues(alpha: 0.3),
        Colors.white.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final bgPaint = Paint()
      ..shader = bgGradient.createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Smooth Bezier Curve matching screenshot:
    final path = Path();
    path.moveTo(0, height * 0.78);

    // First curve to the crest
    final p1 = Offset(width * 0.14, height * 0.70);
    final p2 = Offset(width * 0.20, height * 0.25);
    final crest = Offset(width * 0.28, height * 0.25);
    path.cubicTo(p1.dx, p1.dy, p2.dx, p2.dy, crest.dx, crest.dy);

    // Valley curve
    final p3 = Offset(width * 0.38, height * 0.25);
    final p4 = Offset(width * 0.44, height * 0.48);
    final valley = Offset(width * 0.54, height * 0.46);
    path.cubicTo(p3.dx, p3.dy, p4.dx, p4.dy, valley.dx, valley.dy);

    // Ascend to right edge
    final p5 = Offset(width * 0.66, height * 0.42);
    final p6 = Offset(width * 0.82, height * 0.20);
    final endPoint = Offset(width, height * 0.15);
    path.cubicTo(p5.dx, p5.dy, p6.dx, p6.dy, endPoint.dx, endPoint.dy);

    // Stroke paint for curve line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(path, linePaint);

    // Filled marker dot at the crest
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Subtle outer halo around dot
    final haloPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(crest, 7.5, haloPaint);
    canvas.drawCircle(crest, 4.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DailySnapshotCurveWidget extends StatelessWidget {
  final double height;
  const DailySnapshotCurveWidget({super.key, this.height = 76});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crestX = constraints.maxWidth * 0.28;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: DailySnapshotCurvePainter(),
                ),
              ),
              // "XXXX" pill badge matching screenshot 3
              Positioned(
                left: (crestX - 28).clamp(8.0, double.infinity),
                top: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0ECFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'XXXX',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E60F2),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
