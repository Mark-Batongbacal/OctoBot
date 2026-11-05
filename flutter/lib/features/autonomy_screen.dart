import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';
import '../core/robot_connection.dart';
import '../widgets/panels.dart';

class AutonomyScreen extends StatelessWidget {
  const AutonomyScreen({required this.robot, super.key});
  final RobotConnection robot;

  @override
  Widget build(BuildContext context) {
    final active = robot.telemetryFresh && robot.telemetry.mode == 'autonomous';
    final obstacle = robot.telemetry.obstacle;
    return PageFrame(children: [
      const PageHeading(title: 'Autonomy',
        subtitle: 'ESP32-managed obstacle detection and directional decisions'),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Overline('CONTROL MODE'),
        const SizedBox(height: 10),
        Row(children: [
          Icon(active ? Icons.radar : Icons.route_outlined,
            size: 35, color: OctoColors.teal),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(active ? 'Autonomy reported active' : 'Autonomous navigation',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text(robot.connected
                ? 'Commands require confirmation from ESP32 firmware.'
                : 'Connect your robot to start.',
                style: const TextStyle(fontSize: 12, color: OctoColors.muted)),
            ],
          )),
        ]),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: robot.connected
              ? () => robot.requestMode(active ? 'manual' : 'autonomous') : null,
          icon: Icon(active ? Icons.pause_circle_outline : Icons.play_arrow),
          label: Text(active ? 'Request manual mode' : 'Request autonomous mode'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: robot.connected ? robot.stop : null,
          icon: const Icon(Icons.stop_circle_outlined, color: OctoColors.danger),
          label: const Text('Stop motion'),
        ),
      ])),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Overline('LIVE SENSOR'),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.sensors_outlined, color: OctoColors.muted, size: 31),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(robot.telemetry.distanceCm == null ? '— cm'
                : '${robot.telemetry.distanceCm!.toStringAsFixed(1)} cm',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 26)),
            const Text('Front distance', style: TextStyle(
              fontSize: 12, color: OctoColors.muted)),
          ])),
          Text(obstacle == null ? 'NO DATA' : obstacle ? 'OBSTACLE' : 'CLEAR',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11,
              color: obstacle == null ? OctoColors.muted
                  : obstacle ? OctoColors.danger : OctoColors.teal)),
        ]),
      ])),
      const Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Overline('PLANNED ESP32 DECISION LOOP'),
        SizedBox(height: 13),
        _Step(number: '01', title: 'Observe', description: 'Measure forward clearance'),
        _Step(number: '02', title: 'Stop', description: 'Inhibit unsafe gait progression'),
        _Step(number: '03', title: 'Scan', description: 'Rotate slowly and re-measure'),
        _Step(number: '04', title: 'Proceed', description: 'Continue only when a path is clear'),
      ])),
      const Text('Autonomous walking and obstacle avoidance belong to the ESP32 firmware. '
          'This screen does not simulate or claim those behaviors.',
        style: TextStyle(fontSize: 11.5, color: OctoColors.muted)),
    ]);
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.description});
  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Row(children: [
      Container(width: 36, height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: OctoColors.canvas,
          borderRadius: BorderRadius.circular(10)),
        child: Text(number, style: const TextStyle(
          fontWeight: FontWeight.w800, color: OctoColors.muted, fontSize: 11))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        Text(description, style: const TextStyle(fontSize: 12, color: OctoColors.muted)),
      ])),
    ]),
  );
}
