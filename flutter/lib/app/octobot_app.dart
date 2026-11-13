import 'package:flutter/material.dart';

import '../core/robot_connection.dart';
import '../features/autonomy_screen.dart';
import '../features/connection_screen.dart';
import '../features/drive_screen.dart';
import '../features/monitor_screen.dart';
import '../widgets/panels.dart';
import 'octobot_theme.dart';

class OctoBotApp extends StatefulWidget {
  const OctoBotApp({super.key});

  @override
  State<OctoBotApp> createState() => _OctoBotAppState();
}

class _OctoBotAppState extends State<OctoBotApp> {
  final RobotConnection _robot = RobotConnection();
  int _tab = 0;

  @override
  void dispose() {
    _robot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OctoBot Control',
    debugShowCheckedModeBanner: false,
    theme: buildOctoTheme(),
    home: AnimatedBuilder(
      animation: _robot,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(children: [
            _TopBar(robot: _robot, onConnect: () => setState(() => _tab = 3)),
            Expanded(
              child: IndexedStack(index: _tab, children: [
                DriveScreen(robot: _robot),
                AutonomyScreen(robot: _robot),
                MonitorScreen(robot: _robot),
                ConnectionScreen(robot: _robot),
              ]),
            ),
          ]),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: OctoColors.line)),
          ),
          child: NavigationBar(
            height: 72,
            selectedIndex: _tab,
            onDestinationSelected: (index) {
              // Leaving Drive stops active manual movement, but must not
              // unexpectedly cancel autonomous mode or idle monitoring.
              if (index != _tab && _tab == 0 && _robot.hasMotion) {
                _robot.stop();
              }
              setState(() => _tab = index);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.gamepad_outlined),
                selectedIcon: Icon(Icons.gamepad), label: 'Drive'),
              NavigationDestination(icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.navigation), label: 'Autonomy'),
              NavigationDestination(icon: Icon(Icons.monitor_heart_outlined),
                selectedIcon: Icon(Icons.monitor_heart), label: 'Monitor'),
              NavigationDestination(icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune), label: 'Connect'),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.robot, required this.onConnect});
  final RobotConnection robot;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => Container(
    color: OctoColors.canvas,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
    child: Row(children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: OctoColors.dark, borderRadius: BorderRadius.circular(11),
        ),
        child: const Icon(Icons.hub_outlined, color: Colors.white, size: 20),
      ),
      const SizedBox(width: 11),
      const Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OCTOBOT', style: TextStyle(fontSize: 16, letterSpacing: 1.6,
              fontWeight: FontWeight.w900, color: OctoColors.ink)),
          Overline('FIELD CONTROLLER'),
        ],
      )),
      InkWell(
        onTap: onConnect,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(
              color: robot.connected ? OctoColors.teal : OctoColors.muted,
              shape: BoxShape.circle,
            )),
            const SizedBox(width: 7),
            Text(robot.connecting ? 'CONNECTING' : robot.connected ? 'LINKED' : 'OFFLINE',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                color: OctoColors.ink, letterSpacing: .8)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 15, color: OctoColors.muted),
          ]),
        ),
      ),
    ]),
  );
}
