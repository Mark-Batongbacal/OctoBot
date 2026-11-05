import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';
import '../core/robot_connection.dart';
import '../widgets/panels.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({required this.robot, super.key});
  final RobotConnection robot;

  @override
  Widget build(BuildContext context) {
    final telemetry = robot.telemetry;
    final last = telemetry.receivedAt;
    final stamp = last == null
        ? 'No telemetry received'
        : 'Last update ${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}:${last.second.toString().padLeft(2, '0')}';
    return PageFrame(children: [
      const PageHeading(title: 'Monitor',
        subtitle: 'Actual telemetry from the ESP32, never simulated'),
      Row(children: [
        Expanded(child: _Metric(icon: Icons.battery_5_bar_outlined,
          label: 'BATTERY', value: telemetry.batteryVoltage == null ? '— V'
              : '${telemetry.batteryVoltage!.toStringAsFixed(2)} V')),
        const SizedBox(width: 10),
        Expanded(child: _Metric(icon: Icons.straighten_outlined,
          label: 'DISTANCE', value: telemetry.distanceCm == null ? '— cm'
              : '${telemetry.distanceCm!.toStringAsFixed(1)} cm')),
      ]),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Overline('ROBOT STATUS'),
        const SizedBox(height: 8),
        RowInfo(label: 'Connection', value: robot.connected ? 'WebSocket linked' : 'Offline',
          trailing: Icon(Icons.circle, size: 9,
            color: robot.connected ? OctoColors.teal : OctoColors.muted)),
        const Divider(height: 1, color: OctoColors.line),
        RowInfo(label: 'Mode', value: telemetry.mode ?? 'Not reported'),
        const Divider(height: 1, color: OctoColors.line),
        RowInfo(label: 'Robot state', value: telemetry.state ?? 'Not reported'),
        const Divider(height: 1, color: OctoColors.line),
        RowInfo(label: 'Gait phase', value: telemetry.gaitPhase ?? 'Not reported'),
        const Divider(height: 1, color: OctoColors.line),
        RowInfo(label: 'Obstacle', value: telemetry.obstacle == null
          ? 'Unknown' : telemetry.obstacle! ? 'Detected' : 'Clear'),
        const Divider(height: 1, color: OctoColors.line),
        const SizedBox(height: 10),
        Text(last == null ? stamp : robot.telemetryFresh ? stamp : '$stamp  ·  STALE',
          style: const TextStyle(color: OctoColors.muted, fontSize: 11)),
      ])),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Overline('RECENT EVENTS'),
        const SizedBox(height: 13),
        if (robot.events.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text('No events recorded in this session.',
              style: TextStyle(color: OctoColors.muted, fontSize: 12))),
          )
        else
          for (final event in robot.events.take(8)) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 5),
                child: Icon(Icons.circle, size: 6, color: OctoColors.teal)),
              const SizedBox(width: 9),
              Expanded(child: Text(event,
                style: const TextStyle(fontSize: 12, height: 1.4))),
            ]),
            const SizedBox(height: 12),
          ],
      ])),
      const Text('All reported values depend on the future Arduino/ESP32 protocol. '
          'The safety controller must run on the robot, not this screen.',
        style: TextStyle(fontSize: 11.5, color: OctoColors.muted)),
    ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Panel(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 24, color: OctoColors.teal),
      const SizedBox(height: 18),
      Overline(label),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(fontSize: 23,
        fontWeight: FontWeight.w900, letterSpacing: -.5)),
    ],
  ));
}
