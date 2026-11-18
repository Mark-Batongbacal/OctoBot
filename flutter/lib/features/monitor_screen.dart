import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';
import '../core/robot_connection.dart';
import '../widgets/panels.dart';

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({required this.robot, super.key});
  final RobotConnection robot;

  @override
  Widget build(BuildContext context) {
    final t = robot.telemetry;
    final fresh = robot.telemetryFresh;
    // Keep valid close-range readings visible while Forward is blocked.
    final valid = fresh && t.sensorValid == true && t.distanceCm != null;
    final warning = fresh && t.safetyBlocked != false;
    final last = t.receivedAt;
    final updated = last == null ? 'No telemetry received'
      : 'Last update ${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}:${last.second.toString().padLeft(2, '0')}';

    return PageFrame(children: [
      const PageHeading(title: 'Monitor',
        subtitle: 'Live obstacle safety and movement status'),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Overline('FRONT DISTANCE'),
        const SizedBox(height: 14),
        Text(valid ? '${t.distanceCm!.toStringAsFixed(1)} cm' : '— cm',
          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900,
            color: valid && t.distanceCm! <= 20.0 ? OctoColors.danger : OctoColors.ink)),
        const SizedBox(height: 12),
        Row(children: [
          Icon(warning ? Icons.warning_amber_rounded : Icons.sensors_outlined,
            color: warning ? OctoColors.danger : OctoColors.teal),
          const SizedBox(width: 10),
          Expanded(child: Text(!valid ? 'Sensor data unavailable'
              : warning ? 'Forward blocked (${t.distanceCm!.toStringAsFixed(1)} cm)' : 'Forward path clear',
            style: TextStyle(fontWeight: FontWeight.w800,
              color: warning ? OctoColors.danger : OctoColors.ink))),
        ]),
        const SizedBox(height: 8),
        const Text('Only Forward stops within 20 cm; one valid reading at 25 cm unlocks Forward.',
          style: TextStyle(fontSize: 12, color: OctoColors.muted)),
      ])),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Overline('SYSTEM STATUS'),
        const SizedBox(height: 10),
        RowInfo(label: 'Connection',
          value: robot.connected ? 'WebSocket linked' : 'Offline'),
        const Divider(height: 1, color: OctoColors.line),
        RowInfo(label: 'Movement',
          value: fresh ? (t.state ?? 'Unknown') : 'Unknown'),
        const Divider(height: 1, color: OctoColors.line),
        RowInfo(label: 'Distance data',
          value: valid ? 'Fresh' : 'Unavailable or stale'),
        const Divider(height: 1, color: OctoColors.line),
        RowInfo(label: 'Safety',
          value: !fresh ? 'Telemetry stale' : warning ? 'Forward locked' : 'Forward ready'),
        const SizedBox(height: 12),
        Text(!fresh && last != null ? '$updated · STALE' : updated,
          style: const TextStyle(fontSize: 11, color: OctoColors.muted)),
      ])),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Overline('RECENT EVENTS'),
        const SizedBox(height: 12),
        if (robot.events.isEmpty)
          const Text('No events recorded in this session.',
            style: TextStyle(fontSize: 12, color: OctoColors.muted))
        else
          for (final event in robot.events.take(8))
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: Text(event, style: const TextStyle(fontSize: 12))),
      ])),
      const Text('Distance measurements are informational only. '
        'A software STOP is not a physical emergency cutoff.',
        style: TextStyle(fontSize: 11.5, color: OctoColors.muted)),
    ]);
  }
}
