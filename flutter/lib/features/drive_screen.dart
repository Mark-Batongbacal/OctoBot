import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';
import '../core/robot_connection.dart';
import '../widgets/panels.dart';

class DriveScreen extends StatelessWidget {
  const DriveScreen({required this.robot, super.key});
  final RobotConnection robot;

  @override
  Widget build(BuildContext context) {
    final distance = robot.telemetry.distanceCm;
    final fresh = robot.telemetryFresh;
    final detected = fresh && robot.telemetry.obstacle == true;
    final enabled = robot.manualArmed;

    return Column(children: [
      Expanded(child: PageFrame(children: [
        const PageHeading(title: 'Drive',
          subtitle: 'Walk, pivot in place and monitor proximity'),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Overline('FRONT ULTRASONIC SENSOR'),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.sensors_outlined, size: 29, color: OctoColors.teal),
            const SizedBox(width: 12),
            Expanded(child: Text(
              fresh && distance != null ? '${distance.toStringAsFixed(1)} cm' : '— cm',
              style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
            )),
            Text(!fresh || distance == null ? 'NO READING'
                : detected ? 'OBSTACLE DETECTED' : 'CLEAR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                color: detected ? OctoColors.danger : OctoColors.muted)),
          ]),
          const SizedBox(height: 8),
          Text(detected
              ? 'Nearby object detected. This warning does not stop the robot.'
              : 'Distance is monitored only; obstacle sensing does not control movement.',
            style: TextStyle(fontSize: 12,
              color: detected ? OctoColors.danger : OctoColors.muted)),
        ])),
        Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Overline('MANUAL MOVEMENT'),
          const SizedBox(height: 10),
          Text(robot.motionLockReason, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: OctoColors.muted)),
          const SizedBox(height: 18),
          _HoldDirection(
            label: 'FORWARD', icon: Icons.arrow_upward_rounded,
            enabled: enabled,
            onStart: () => robot.setMotion(nextForward: 0.65, nextTurn: 0),
            onEnd: robot.stop,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: robot.connected ? robot.stop : null,
            style: FilledButton.styleFrom(
              backgroundColor: OctoColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(60)),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('STOP MOTION',
              style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 14),
          _HoldDirection(
            label: 'BACKWARD', icon: Icons.arrow_downward_rounded,
            enabled: enabled,
            onStart: () => robot.setMotion(nextForward: -0.65, nextTurn: 0),
            onEnd: robot.stop,
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _HoldDirection(
              label: 'LEFT', icon: Icons.turn_left_rounded,
              enabled: enabled,
              onStart: () => robot.setMotion(nextForward: 0, nextTurn: -0.65),
              onEnd: robot.stop,
            )),
            const SizedBox(width: 12),
            Expanded(child: _HoldDirection(
              label: 'RIGHT', icon: Icons.turn_right_rounded,
              enabled: enabled,
              onStart: () => robot.setMotion(nextForward: 0, nextTurn: 0.65),
              onEnd: robot.stop,
            )),
          ]),
          const SizedBox(height: 14),
          const Text('Hold to move; release to stop. Left and right rotate '
            'in place using the eight-leg alternating gait.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: OctoColors.muted)),
        ])),
      ])),
      Container(
        width: double.infinity,
        color: OctoColors.canvas,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: const Text(
          'Ultrasonic detection is a warning only. Use a physical emergency power cutoff.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: OctoColors.muted)),
      ),
    ]);
  }
}

class _HoldDirection extends StatelessWidget {
  const _HoldDirection({required this.label, required this.icon,
    required this.enabled, required this.onStart, required this.onEnd});

  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Hold to move ${label.toLowerCase()}, release to stop',
    button: true,
    enabled: enabled,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => onStart() : null,
      onTapUp: enabled ? (_) => onEnd() : null,
      onTapCancel: enabled ? onEnd : null,
      child: Container(
        height: 78,
        decoration: BoxDecoration(
          color: enabled ? OctoColors.tealWash : OctoColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OctoColors.line)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 30,
            color: enabled ? OctoColors.teal : OctoColors.muted),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w900,
            color: enabled ? OctoColors.ink : OctoColors.muted)),
        ]),
      ),
    ),
  );
}
