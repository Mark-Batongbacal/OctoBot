# OctoBot Flutter control UI — implementation handoff

**Scope:** Flutter mobile app only. Existing Arduino sketch files are untouched.

## Implemented

- Real UI for Drive, Autonomy, Monitor, Connect with Material 3 and a neutral
  hardware-instrument design. No AI image assets or remote UI dependencies.
- Drawn robot schematic with **exactly eight legs**. Pair 1 and 3 are blue,
  Pair 2 and 4 are orange. Diagram documents reciprocal swing phases separately.
- 2-axis joystick with normalized forward/turn, dead zone, return-to-center,
  stop-on-release and stop-on-navigation-away.
- Selectable primary reciprocal/wave gait and speed setting.
- WebSocket client with connect/disconnect/error/reconnect attempt,
  JSON command encoding, continuous active motion commands and heartbeats.
- Actual telemetry only: no fabricated battery, distance or gait state.
- Explicit locking of motion until connected with ESP32-reported manual mode.
- Android local-network permissions and tests.

## Pending until the instructor authorizes Arduino development

- Implement and verify the exact WebSocket endpoint and JSON protocol.
- ESP32 safety state machine, FreeRTOS tasks, physical emergency-stop behavior.
- Servo calibration UI/data contract (do not send raw positions until firmware
  provides safe mechanical limits and exclusive maintenance-mode authorization).
- Sensor thresholds, fault codes, battery interpretation and gait phase reporting.
- Real hardware connectivity tests, stop latency measurement and recovery policy.

## Intentional design constraints

Mobile-first, 48dp-or-larger primary interactive targets, no fictional readings,
no uncontrolled use of all 16 servos from Flutter. Commands express desired
movement rather than raw SG90 angles. 'Diagonal' joystick operation means forward
plus turn: a curved trajectory, not guaranteed sideways strafe.

## Deployment

Apply this overlay at the **root** of Mark-Batongbacal/OctoBot and then run
`cd flutter && flutter pub get && flutter analyze && flutter test && flutter devices && flutter run -d <ANDROID_DEVICE_ID>`.
No files under the root firmware scaffold are altered.

## Android-only correction

Widget tests import `package:octobot/app/octobot_app.dart` directly instead of
`package:octobot/main.dart`, which does not re-export `OctoBotApp`.

The unused iOS/Swift Xcode runner and iOS Flutter platform metadata have been
removed. Select an Android device explicitly when running (`flutter devices`,
then `flutter run -d <ANDROID_DEVICE_ID>`).
