import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';

/// Normed joystick: x > 0 = turn right, y < 0 = forward.
/// On release it ALWAYS emits zero, even when a gesture is canceled.
class DriveJoystick extends StatefulWidget {
  const DriveJoystick({required this.enabled, required this.onChanged, super.key});
  final bool enabled;
  final ValueChanged<Offset> onChanged;

  @override
  State<DriveJoystick> createState() => _DriveJoystickState();
}

class _DriveJoystickState extends State<DriveJoystick> {
  static const double _diameter = 232;
  Offset _position = Offset.zero;

  void _update(Offset local) {
    if (!widget.enabled) return;
    var pos = (local - const Offset(_diameter / 2, _diameter / 2)) /
        (_diameter * .31);
    if (pos.distance > 1) pos /= pos.distance;
    if (pos.distance < .12) pos = Offset.zero;
    setState(() => _position = pos);
    widget.onChanged(pos);
  }

  void _release() {
    setState(() => _position = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  void didUpdateWidget(covariant DriveJoystick oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The connection model already sends STOP when the link/mode goes unsafe.
    // Do not notify the model during Flutter's build lifecycle.
    if (oldWidget.enabled && !widget.enabled) _position = Offset.zero;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Directional joystick: drag to drive, release to stop',
    enabled: widget.enabled,
    child: IgnorePointer(
      ignoring: !widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (d) => _update(d.localPosition),
        onPanUpdate: (d) => _update(d.localPosition),
        onPanEnd: (_) => _release(),
        onPanCancel: _release,
        child: SizedBox.square(
          dimension: _diameter,
          child: CustomPaint(painter: _JoystickPainter(_position)),
        ),
      ),
    ),
  );
}

class _JoystickPainter extends CustomPainter {
  const _JoystickPainter(this.position);
  final Offset position;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width * .45;
    canvas.drawCircle(center, outer, Paint()..color = OctoColors.canvas);
    canvas.drawCircle(center, outer, Paint()
      ..color = OctoColors.line
      ..style = PaintingStyle.stroke..strokeWidth = 1.4);
    canvas.drawCircle(center, outer * .67, Paint()
      ..color = const Color(0xFFD0DAD5)
      ..style = PaintingStyle.stroke..strokeWidth = 1.0);
    final cross = Paint()..color = const Color(0xFFCFD9D5)..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx - 80, center.dy), Offset(center.dx + 80, center.dy), cross);
    canvas.drawLine(Offset(center.dx, center.dy - 80), Offset(center.dx, center.dy + 80), cross);

    // Minimal compass marks, no effects or exaggerated gradients.
    for (var i = 0; i < 4; i++) {
      final theta = i * math.pi / 2;
      final p0 = center + Offset(math.cos(theta), math.sin(theta)) * 84;
      final p1 = center + Offset(math.cos(theta), math.sin(theta)) * 91;
      canvas.drawLine(p0, p1, Paint()..color = OctoColors.muted..strokeWidth = 2);
    }
    final knob = center + position * (size.width * .31);
    canvas.drawCircle(knob, 35, Paint()..color = OctoColors.dark);
    canvas.drawCircle(knob, 34, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF63787C));
    canvas.drawCircle(knob, 7, Paint()..color = const Color(0xFFE2F1EC));
  }

  @override
  bool shouldRepaint(covariant _JoystickPainter oldDelegate) => oldDelegate.position != position;
}
