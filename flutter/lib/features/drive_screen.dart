import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';
import '../core/robot_connection.dart';
import '../widgets/drive_joystick.dart';
import '../widgets/panels.dart';
import '../widgets/robot_schematic.dart';

class DriveScreen extends StatelessWidget {
  const DriveScreen({required this.robot, super.key});
  final RobotConnection robot;

  @override
  Widget build(BuildContext context) {
    final motionAllowed = robot.manualArmed;
    return Column(children: [
      Expanded(child: PageFrame(children: [
      const PageHeading(title: 'Drive',
        subtitle: 'Hold to drive forward, reverse, rotate or steer diagonally'),
      _RobotCard(robot: robot),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Overline('MOVEMENT'),
              SizedBox(height: 3),
              Text('Directional control', style: TextStyle(fontSize: 18,
                fontWeight: FontWeight.w800)),
            ],
          )),
          if (motionAllowed)
            const Icon(Icons.lock_open_rounded, color: OctoColors.teal)
          else
            const Icon(Icons.lock_outline_rounded, color: OctoColors.muted),
        ]),
        const SizedBox(height: 10),
        Center(child: DriveJoystick(
          enabled: motionAllowed,
          onChanged: (value) => robot.setMotion(
            nextForward: -value.dy, nextTurn: value.dx,
          ),
        )),
        Text(
          robot.motionLockReason,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: OctoColors.muted),
        ),
        if (robot.connected && !motionAllowed) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => robot.requestMode('manual'),
            icon: const Icon(Icons.pan_tool_alt_outlined),
            label: const Text('Request manual mode'),
          ),
        ],
        const SizedBox(height: 18),
        const Overline('HOLD-TO-MOVE DIRECTIONS'),
        const SizedBox(height: 8),
        _DirectionPad(robot: robot, enabled: motionAllowed),
        const SizedBox(height: 6),
        const Text(
          'Left/right rotate the body; diagonals are curved steering, not lateral strafing. '
          'Sideways is unavailable until the leg geometry is validated.',
          style: TextStyle(fontSize: 11, color: OctoColors.muted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(children: [
          const Expanded(child: Text('Walking speed', style: TextStyle(
            fontWeight: FontWeight.w700))),
          Text('${(robot.speed * 100).round()}%',
            style: const TextStyle(fontWeight: FontWeight.w800, color: OctoColors.teal)),
        ]),
        Slider(
          min: .10, max: 1, divisions: 18,
          value: robot.speed,
          label: '${(robot.speed * 100).round()}%',
          onChanged: robot.setSpeed,
        ),
        if (robot.telemetry.speedCap != null)
          Text(
            'ESP32 commissioning cap: ${(robot.telemetry.speedCap! * 100).round()}% '
            '(higher app settings cannot override it)',
            style: const TextStyle(fontSize: 11, color: OctoColors.muted),
          ),
        const SizedBox(height: 4),
        const Overline('GAIT PROFILE'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _GaitButton(
            label: 'Reciprocal', note: 'Primary',
            active: robot.gait == 'reciprocal',
            onPressed: () => robot.setGait('reciprocal'),
          )),
          const SizedBox(width: 10),
          Expanded(child: _GaitButton(
            label: 'Wave', note: 'Fallback',
            active: robot.gait == 'wave',
            onPressed: () => robot.setGait('wave'),
          )),
        ]),
      ])),
    ])),
      Container(
        color: OctoColors.canvas,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: OctoColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(58),
              ),
              onPressed: () {
                robot.stop();
                if (!robot.connected) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Robot offline — no STOP command was transmitted.'),
                  ));
                }
              },
              icon: const Icon(Icons.stop_circle_outlined, size: 25),
              label: const Text('STOP MOTION', style: TextStyle(fontSize: 16,
                fontWeight: FontWeight.w900, letterSpacing: 1)),
            )),
            const SizedBox(height: 4),
            const Text('Software stop — physical emergency cutoff required',
              style: TextStyle(color: OctoColors.muted, fontSize: 10.5)),
          ]),
        )),
      ),
    ]);
  }
}

class _RobotCard extends StatelessWidget {
  const _RobotCard({required this.robot});
  final RobotConnection robot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
    decoration: BoxDecoration(
      color: OctoColors.dark,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Overline('OCTOPOD / TOP VIEW', color: Color(0xFFB4C3C4))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF35444B),
            borderRadius: BorderRadius.circular(8)),
          child: Text(robot.telemetry.gaitPhase == null
              ? 'GAIT —' : 'PHASE ${robot.telemetry.gaitPhase}',
            style: const TextStyle(color: Colors.white, fontSize: 10,
              fontWeight: FontWeight.w800, letterSpacing: .8)),
        ),
      ]),
      const SizedBox(height: 7),
      const RobotSchematic(),
      const SizedBox(height: 9),
      const GroupLegend(onDark: true),
    ]),
  );
}

class _GaitButton extends StatelessWidget {
  const _GaitButton({required this.label, required this.note,
    required this.active, required this.onPressed});
  final String label;
  final String note;
  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 14),
      backgroundColor: active ? OctoColors.tealWash : OctoColors.paper,
      side: BorderSide(color: active ? OctoColors.teal : OctoColors.line),
    ),
    child: Column(children: [
      Text(label, style: TextStyle(color: OctoColors.ink,
        fontSize: 13, fontWeight: active ? FontWeight.w800 : FontWeight.w600)),
      const SizedBox(height: 3),
      Text(note, style: const TextStyle(fontSize: 10, color: OctoColors.muted)),
    ]),
  );
}


/// Press and hold for continuous commands; release/cancel always stops.
/// Forward+turn inputs are differential steering, not true strafing.
class _DirectionPad extends StatelessWidget {
  const _DirectionPad({required this.robot, required this.enabled});
  final RobotConnection robot;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(children: [
    Row(children: [
      _button('Forward left', Icons.north_west, 0.65, -0.35),
      _button('Forward', Icons.north, 0.65, 0),
      _button('Forward right', Icons.north_east, 0.65, 0.35),
    ]),
    const SizedBox(height: 6),
    Row(children: [
      _button('Turn left', Icons.rotate_left, 0, -0.6),
      Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: OutlinedButton(
          onPressed: robot.stop,
          child: const Text('STOP'),
        ),
      )),
      _button('Turn right', Icons.rotate_right, 0, 0.6),
    ]),
    const SizedBox(height: 6),
    Row(children: [
      _button('Reverse left', Icons.south_west, -0.65, -0.35),
      _button('Reverse', Icons.south, -0.65, 0),
      _button('Reverse right', Icons.south_east, -0.65, 0.35),
    ]),
  ]);

  Widget _button(String label, IconData icon, double forward, double turn) =>
      Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Semantics(
          label: 'Hold to $label; release to stop',
          button: true,
          enabled: enabled,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => robot.setMotion(
                nextForward: forward, nextTurn: turn) : null,
            onTapUp: enabled ? (_) => robot.setMotion(
                nextForward: 0, nextTurn: 0) : null,
            onTapCancel: enabled ? () => robot.setMotion(
                nextForward: 0, nextTurn: 0) : null,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: enabled ? OctoColors.tealWash : OctoColors.canvas,
                border: Border.all(color: OctoColors.line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 21,
                    color: enabled ? OctoColors.teal : OctoColors.muted),
                  Text(label, textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9, color: OctoColors.muted)),
                ],
              ),
            ),
          ),
        ),
      ));
}
