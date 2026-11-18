import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';
import '../core/robot_connection.dart';
import '../widgets/panels.dart';

/// One active touch/pointer at a time. A blocked hold cannot silently restart:
/// the pointer must be released before another press is accepted.
class DriveScreen extends StatefulWidget {
  const DriveScreen({required this.robot, super.key});
  final RobotConnection robot;

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  String? _heldDirection;
  int? _heldPointer;

  void _press(String direction, int pointer, double forward, double turn) {
    if (_heldPointer != null || !widget.robot.manualArmed) return;
    setState(() {
      _heldDirection = direction;
      _heldPointer = pointer;
    });
    widget.robot.setMotion(nextForward: forward, nextTurn: turn);
  }

  void _release(int pointer) {
    if (_heldPointer != pointer) return;
    setState(() {
      _heldDirection = null;
      _heldPointer = null;
    });
    widget.robot.stop();
  }

  Widget _direction({
    required String label,
    required IconData icon,
    required double forward,
    required double turn,
    double height = 84,
  }) {
    final held = _heldDirection == label;
    final blocked = !widget.robot.manualArmed;
    final enabled = !blocked && (_heldDirection == null || held);
    final active = held && !blocked;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Hold $label to move; release to stop',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) =>
            _press(label, event.pointer, forward, turn),
        onPointerUp: (event) => _release(event.pointer),
        onPointerCancel: (event) => _release(event.pointer),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          height: height,
          decoration: BoxDecoration(
            color: active ? OctoColors.teal : held
                ? OctoColors.tealWash
                : enabled ? OctoColors.tealWash : OctoColors.canvas,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? OctoColors.teal : OctoColors.line,
              width: active ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: enabled || held ? 1 : 0.45,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 27,
                  color: active ? Colors.white : OctoColors.teal),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 12, letterSpacing: 0.8,
                fontWeight: FontWeight.w900,
                color: active ? Colors.white : OctoColors.ink,
              )),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final robot = widget.robot;
    final t = robot.telemetry;
    final fresh = robot.telemetryFresh;
    final readingAvailable = fresh && t.sensorValid == true &&
        t.distanceCm != null;
    final blocked = !robot.manualArmed;
    final close = readingAvailable && t.obstacle == true;
    final safetyMessage = !robot.connected ? 'Connect to begin' :
        !fresh ? 'Waiting for live telemetry' :
        t.sensorValid != true ? 'SENSOR UNAVAILABLE' :
        t.safetyBlocked != false ? 'MOVEMENT BLOCKED' : 'READY TO MOVE';
    final activeText = _heldDirection != null
        ? (blocked ? 'Interrupted · release your finger' :
           'Holding $_heldDirection · other directions locked')
        : robot.motionLockReason;

    return Column(children: [
      Expanded(child: PageFrame(children: [
        const PageHeading(
          title: 'Drive',
          subtitle: 'Hold one direction · Release to stop',
        ),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(close || (fresh && t.safetyBlocked == true)
                ? Icons.shield_outlined : Icons.sensors_outlined,
                color: close || blocked ? OctoColors.danger : OctoColors.teal,
                size: 26),
            const SizedBox(width: 10),
            const Expanded(child: Overline('FRONT DISTANCE')),
            Text(
              readingAvailable ? '${t.distanceCm!.toStringAsFixed(1)} cm' : '— cm',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
          ]),
          const SizedBox(height: 10),
          Text(safetyMessage, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w900,
            color: blocked ? OctoColors.danger : OctoColors.teal,
            letterSpacing: 0.7,
          )),
          const SizedBox(height: 5),
          Text(
            close ? 'Obstacle within 20 cm — ESP32 inhibits all movement.' :
            t.safetyBlocked == true ? 'Wait for 3 readings at 25 cm or farther.' :
            !readingAvailable ? 'No reliable reading. Movement is disabled.' :
            'Sensor clear. New press required after any interruption.',
            style: const TextStyle(fontSize: 12, color: OctoColors.muted),
          ),
        ])),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Overline('DIRECTIONAL CONTROLLER'),
          const SizedBox(height: 10),
          Text(activeText, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: OctoColors.muted)),
          const SizedBox(height: 16),
          Center(child: SizedBox(width: 150, child: _direction(
            label: 'FORWARD', icon: Icons.keyboard_arrow_up_rounded,
            forward: 0.65, turn: 0,
          ))),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _direction(
              label: 'LEFT', icon: Icons.rotate_left_rounded,
              forward: 0, turn: 0.65, // Physical steering reversal
            )),
            const SizedBox(width: 10),
            Container(
              width: 74, height: 84,
              decoration: BoxDecoration(
                color: OctoColors.canvas,
                border: Border.all(color: OctoColors.line),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(blocked ? Icons.lock_outline : _heldDirection == null
                    ? Icons.pan_tool_alt_outlined : Icons.lock_clock_outlined,
                    color: blocked ? OctoColors.danger : OctoColors.teal),
                const SizedBox(height: 4),
                Text(blocked ? 'LOCKED' : _heldDirection == null ? 'IDLE' : 'HELD',
                  style: const TextStyle(fontSize: 10,
                    color: OctoColors.muted, fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(child: _direction(
              label: 'RIGHT', icon: Icons.rotate_right_rounded,
              forward: 0, turn: -0.65, // Physical steering reversal
            )),
          ]),
          const SizedBox(height: 10),
          Center(child: SizedBox(width: 150, child: _direction(
            label: 'BACKWARD', icon: Icons.keyboard_arrow_down_rounded,
            forward: -0.65, turn: 0,
          ))),
          const SizedBox(height: 14),
          const Text(
            'Only one direction at a time. Lift your finger to stop. '
            'When blocked, release and press again after clearance.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: OctoColors.muted),
          ),
        ])),
      ])),
      Container(
        width: double.infinity,
        color: OctoColors.canvas,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: const Text(
          'Software obstacle detection is not a physical emergency cutoff.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: OctoColors.muted),
        ),
      ),
    ]);
  }
}
