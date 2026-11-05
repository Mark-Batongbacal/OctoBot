import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';

/// A technical top view with exactly four mirrored pairs (eight legs total).
/// Pair colors identify physical rows, NOT the reciprocal swing groups:
/// swing A = L1/R2/L3/R4, swing B = R1/L2/R3/L4.
class RobotSchematic extends StatelessWidget {
  const RobotSchematic({super.key});

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 2.18,
    child: CustomPaint(painter: _RobotPainter()),
  );
}

class _RobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final bodyWidth = w * .22;
    final bodyHeight = h * .82;
    final top = (h - bodyHeight) / 2;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(centerX, h / 2), width: bodyWidth, height: bodyHeight),
      const Radius.circular(19),
    );
    final guide = Paint()..color = const Color(0xFF314047)..strokeWidth = .75;
    for (var i = 1; i <= 4; i++) {
      final x = w * i / 5;
      canvas.drawLine(Offset(x, 4), Offset(x, h - 4), guide);
    }
    canvas.drawRRect(bodyRect, Paint()..color = const Color(0xFF34434A));
    canvas.drawRRect(bodyRect.deflate(5), Paint()..color = OctoColors.dark);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(centerX, h / 2), width: bodyWidth * .56, height: bodyHeight * .45),
        const Radius.circular(9),
      ),
      Paint()..color = const Color(0xFF3D4C51),
    );
    final front = Path()
      ..moveTo(centerX, top + 8)
      ..lineTo(centerX - 7, top + 20)
      ..lineTo(centerX + 7, top + 20)
      ..close();
    canvas.drawPath(front, Paint()..color = const Color(0xFF9CD8C9));

    // Exactly 8 legs: four to the left and four to the right.
    for (var row = 0; row < 4; row++) {
      final jointY = top + bodyHeight * (.16 + row * .225);
      final color = row.isEven ? OctoColors.blue : OctoColors.orange;
      for (final side in [-1.0, 1.0]) {
        final root = Offset(centerX + side * bodyWidth * .52, jointY);
        final elbow = Offset(centerX + side * w * .205,
            jointY + (row < 2 ? -1 : 1) * h * .055);
        final foot = Offset(centerX + side * w * .34,
            elbow.dy + h * .043);
        final legPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final leg = Path()
          ..moveTo(root.dx, root.dy)
          ..lineTo(elbow.dx, elbow.dy)
          ..lineTo(foot.dx, foot.dy);
        canvas.drawPath(leg, legPaint);
        canvas.drawCircle(root, 5, Paint()..color = const Color(0xFFD6DFDC));
        canvas.drawCircle(elbow, 3.4, Paint()..color = OctoColors.dark);
        canvas.drawCircle(foot, 4, Paint()..color = color);
        final legText = TextPainter(
          text: TextSpan(text: '${side < 0 ? 'L' : 'R'}${row + 1}',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          textDirection: TextDirection.ltr,
        )..layout();
        legText.paint(canvas, Offset(
          side < 0 ? w * .035 : w * .935 - legText.width,
          jointY - 6,
        ));
      }
    }
    final label = TextPainter(
      text: const TextSpan(text: 'FRONT  ↑', style: TextStyle(
        fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700,
        color: Color(0xFFB0C6C8),
      )),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(w / 2 - label.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
