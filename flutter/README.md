# OctoBot Control — Flutter UI

Android-first field controller for the eight-legged OctoBot. This Flutter-only
implementation replaces the starter page with a restrained, functional robotics
control interface. **The Arduino/ESP32 firmware has not been implemented.**

## Run

From the existing repository root:

```bash
cd flutter
flutter pub get
flutter run
```

Install Android Studio / an Android SDK or connect an Android phone with USB
Debugging enabled. The app starts **offline**. No motor movement, obstacle data,
mode acknowledgement or battery readings are simulated.

## Screens

- **Drive** — top-view eight-leg diagram, analog joystick, reciprocal/wave gait
  selection, 10–100% speed slider, prominent software STOP.
- **Autonomy** — request automatic/manual operation from the ESP32 and display
  genuine front distance and obstacle information when available.
- **Monitor** — battery voltage, distance, current mode/state/phase, event log.
- **Connect** — editable WebSocket URL, connection lifecycle and setup guidance.

The joystick is disabled until the WebSocket is connected **and** the ESP32
explicitly reports fresh `mode: "manual"` and `obstacle: false` telemetry. Releasing the joystick transmits a STOP
request. Navigating away from Drive also sends STOP. When the WebSocket closes,
the app resets motion to zero.

## Gait colors and timing (important)

Physical pairs are color-coded (these are **not** the same as gait swing groups):

- **Blue:** `L1 R1`, `L3 R3`
- **Orange:** `L2 R2`, `L4 R4`

Correct reciprocal stepping groups:

- Swing A: `L1 R2 L3 R4`; stance A: `R1 L2 R3 L4`
- Swing B: `R1 L2 R3 L4`; stance B: `L1 R2 L3 R4`

Opposite legs in each pair counteract one another. The ESP32 will later own
servo calibration, foot placement, support transfer, smooth trajectory generation
and obstacle-aware stopping.

## Proposed protocol (not implemented on ESP32 yet)

Default endpoint: `ws://192.168.4.1/ws` (editable). JSON messages:

Phone -> ESP32:

```json
{"type":"drive","forward":0.75,"turn":-0.25,"speed":0.35,"gait":"reciprocal"}
{"type":"stop"}
{"type":"mode","value":"manual"}
{"type":"mode","value":"autonomous"}
{"type":"heartbeat"}
```

`forward` is -1..+1: positive forward. `turn` is -1..+1: positive right.
`speed` is 0.10..1.00. The UI sends active drive values roughly every 100 ms
and a heartbeat every 500 ms while linked. The actual joystick may also send
immediate updates between periodic ticks. A STOP message should be handled by
ESP32 independently of Flutter interface state.

ESP32 -> phone:

```json
{"type":"telemetry","mode":"manual","state":"standing","gait_phase":"A","battery_voltage":7.72,"distance_cm":42.5,"obstacle":false}
{"type":"event","message":"Gait calibrated"}
{"type":"error","message":"Sensor unavailable"}
```

All numerical fields are optional in incoming telemetry and remain unknown (`—`)
when no real data is provided. These examples describe the intended interface,
not measurements or existing robot behavior. Firmware message definitions may
be revised together during Arduino integration.

## Safety boundaries

The **ESP32 must independently implement** obstacle-based motion inhibition,
manual stop arbitration, command expiry (recommended initial target 300–500 ms),
loss-of-link behavior, fault handling and safe foot planting. FreeRTOS task
priorities and physical emergency power switching are firmware/hardware concerns.
A phone-side STOP button is **not** a physical emergency-stop switch and cannot
guarantee an immediate mechanical halt if connectivity or the MCU fails.

The Android manifest enables cleartext for the ESP32's private local WebSocket
prototype. Do not expose an unencrypted/unauthenticated controller to public Wi-Fi.
Use TLS/authentication or another appropriate trust model for deployment outside
an isolated robot network. iOS will require separate local-network permissions.

## UI design references

- [Flutter: adaptive and responsive design](https://docs.flutter.dev/ui/adaptive-responsive)
- [Flutter: Material widgets](https://docs.flutter.dev/ui/widgets/material)
- [Android: touch target sizes, minimum 48 dp](https://support.google.com/accessibility/android/answer/7101858)
- [Flutter: WebSocket communication](https://docs.flutter.dev/cookbook/networking/web-sockets)
- [AgileX LIMO controller reference](https://docs.trossenrobotics.com/agilex_limo_docs/operation/app.html)
- [Viam mobile robot arm controls](https://www.viam.com/post/january-2026-platform-roundup)

Design goals: clear hierarchy, full-size controls, leg-group color consistency,
real link status, no fake readings, no AI-style illustrations, no gradients,
no ornamental dashboards. UI uses core Flutter widgets and `dart:io` WebSocket
for Android-first local control, requiring **no additional runtime packages**.

## Validation

```bash
flutter analyze
flutter test
flutter run
```

Tests are provided under `test/`. Run them in a local Flutter SDK installation;
this source package was prepared without a Flutter SDK in the execution environment.
