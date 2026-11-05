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
        subtitle: 'Direct control / reciprocal 8-leg walking gait'),
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
          motionAllowed
            ? 'Drag to move · Release to stop'
            : robot.connected
              ? 'Awaiting fresh manual-mode telemetry from robot'
              : 'Connect to OctoBot to enable the joystick',
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
