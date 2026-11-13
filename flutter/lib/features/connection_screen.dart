import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';
import '../core/robot_connection.dart';
import '../widgets/panels.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({required this.robot, super.key});
  final RobotConnection robot;

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  late final TextEditingController _endpoint;

  @override
  void initState() {
    super.initState();
    _endpoint = TextEditingController(text: widget.robot.endpoint);
  }

  @override
  void dispose() {
    _endpoint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final robot = widget.robot;
    return PageFrame(children: [
      const PageHeading(title: 'Connection',
        subtitle: 'Direct local link between your phone and OctoBot'),
      Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: OctoColors.tealWash,
              borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.wifi_tethering, color: OctoColors.teal)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(robot.connected ? 'WebSocket connected' :
                robot.connecting ? 'Connecting…' : 'Robot is offline',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const Text('ESP32 SoftAP / local Wi-Fi', style: TextStyle(
                fontSize: 12, color: OctoColors.muted)),
            ],
          )),
        ]),
        const SizedBox(height: 24),
        const Overline('WEBSOCKET ENDPOINT'),
        const SizedBox(height: 8),
        TextField(
          controller: _endpoint,
          enabled: !robot.connected && !robot.connecting,
          autocorrect: false,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: RobotConnection.defaultEndpoint,
            prefixIcon: Icon(Icons.link_outlined),
          ),
        ),
        if (robot.error != null) ...[
          const SizedBox(height: 12),
          Text(robot.error!, style: const TextStyle(
            color: OctoColors.danger, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        if (robot.connected)
          OutlinedButton.icon(
            onPressed: () => robot.disconnect(),
            icon: const Icon(Icons.link_off_outlined),
            label: const Text('Disconnect safely'),
          )
        else
          FilledButton.icon(
            onPressed: robot.connecting ? null
                : () => robot.connect(_endpoint.text),
            icon: robot.connecting
              ? const SizedBox.square(dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2,
                    color: Colors.white))
              : const Icon(Icons.wifi),
            label: Text(robot.connecting ? 'Connecting…' : 'Connect to OctoBot'),
          ),
      ])),
      const Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Overline('CONNECTION SETUP'),
        SizedBox(height: 14),
        _SetupStep(n: '1', title: 'Power the ESP32',
          description: 'Use a verified regulated logic supply.'),
        _SetupStep(n: '2', title: 'Join OctoBot Wi-Fi',
          description: 'Connect the phone to the ESP32 SoftAP in device Wi-Fi settings.'),
        _SetupStep(n: '3', title: 'Set the endpoint',
          description: 'Match the WebSocket address configured in ESP32 firmware.'),
        _SetupStep(n: '4', title: 'Check telemetry',
          description: 'Movement unlocks only after the robot reports manual mode.'),
      ])),
      Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: OctoColors.tealWash,
          borderRadius: BorderRadius.circular(14)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: OctoColors.teal, size: 21),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Use the modular PlatformIO Arduino-framework firmware in firmware/, '
            'not the empty root-level .ino files. Motion remains locked until '
            'servo calibration, physical E-stop and sensor checks are approved.',
            style: TextStyle(fontSize: 12, height: 1.45))),
        ]),
      ),
      const Text('Local ws:// is intended for the robot’s private SoftAP only. '
          'Do not expose this unauthenticated prototype endpoint to public networks.',
        style: TextStyle(fontSize: 11.5, color: OctoColors.muted)),
    ]);
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({required this.n, required this.title, required this.description});
  final String n;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 28, height: 28,
        decoration: BoxDecoration(color: OctoColors.canvas,
          borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(n, style: const TextStyle(color: OctoColors.teal,
          fontWeight: FontWeight.w900))),
      const SizedBox(width: 11),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800,
            fontSize: 13)),
          const SizedBox(height: 2),
          Text(description, style: const TextStyle(fontSize: 12,
            color: OctoColors.muted)),
        ],
      )),
    ]),
  );
}
