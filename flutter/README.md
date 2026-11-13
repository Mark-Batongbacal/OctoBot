# OctoBot Control — Flutter UI

Android-only field controller for the eight-legged OctoBot. This Flutter-only
implementation replaces the starter page with a restrained, functional robotics
control interface. **The real ESP32 sketch is [`../OctoBot.ino`](../OctoBot.ino), compiled with Arduino IDE alongside [`../src/`](../src/). Motor commands remain locked until physical calibration and safety checks are approved.**

## Run

From the existing repository root:

```bash
cd flutter
flutter pub get
flutter devices
flutter run -d <ANDROID_DEVICE_ID>
```

Install Android Studio / an Android SDK or connect an Android phone with USB
Debugging enabled. The app starts **offline**. No motor movement, obstacle data,
mode acknowledgement or battery readings are simulated.

## Screens

- **Drive** — eight-leg diagram, analog joystick, hold-to-move eight-direction pad,
  reciprocal/wave selection, speed slider and prominent software STOP.
- **Autonomy** — request automatic/manual operation from the ESP32 and display
  genuine front distance and obstacle information when available.
- **Monitor** — battery voltage, distance, current mode/state/phase, event log.
- **Connect** — editable WebSocket URL, connection lifecycle and setup guidance.

Motion controls are disabled until the connection has fresh manual-mode telemetry
with `calibrated=true`, `hardware_armed=true`, `emergency_latched=false` and
`safe_to_drive=true`. A front obstacle blocks **forward** commands but permits
reverse and in-place turns if the sensor remains valid. Releasing a joystick
or directional hold control transmits STOP. Leaving Drive cancels **active
manual movement**, not idle monitoring or autonomous operation. Link loss
resets phone-side movement, with a separate ESP32-side watchdog.

## Gait colors and timing (important)

Physical pairs are color-coded (these are **not** the same as gait swing groups):

- **Blue:** `L1 R1`, `L3 R3`
- **Orange:** `L2 R2`, `L4 R4`

Correct reciprocal stepping groups:

- Swing A: `L1 R2 L3 R4`; stance A: `R1 L2 R3 L4`
- Swing B: `R1 L2 R3 L4`; stance B: `L1 R2 L3 R4`

Opposite legs in each pair counteract one another. The ESP32 software owns gait trajectories, state arbitration and obstacle-aware
stopping. Physical direction, calibration and balance still require commissioning.

## Implemented firmware protocol (physical hardware not yet validated)

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
Diagonals combine forward+turn into *curved steering*. Pure horizontal joystick
input rotates in place; **true sideways strafing is not implemented**.
`speed` is 0.10..1.00. The UI sends active drive values roughly every 100 ms
and a heartbeat every 500 ms while linked. The actual joystick may also send
immediate updates between periodic ticks. A STOP message should be handled by
ESP32 independently of Flutter interface state.

ESP32 -> phone:

```json
{"type":"telemetry","mode":"manual","state":"standing","gait_phase":"-","battery_voltage":null,"distance_cm":null,"obstacle":true,"calibrated":false,"hardware_armed":false,"emergency_latched":false,"safe_to_drive":false,"applied_forward":0,"applied_turn":0,"speed_cap":0.45}
{"type":"event","message":"Gait calibrated"}
{"type":"error","message":"Sensor unavailable"}
```

Fields absent from telemetry remain unknown (`—`) and inhibit control where
safety is concerned. The example is a **hypothetical locked state**, not real
hardware measurements. App and firmware must be flashed/deployed from compatible
versions of this repository.

## Safety boundaries

The **ESP32 firmware implements** obstacle-based forward inhibition, manual
stop arbitration, a 450 ms drive timeout, 1200 ms link timeout and landing
logic, but these behaviors require physical verification before floor testing. FreeRTOS task
priorities and physical emergency power switching are robot firmware/hardware concerns.
A phone-side STOP button is **not** a physical emergency-stop switch and cannot
guarantee an immediate mechanical halt if connectivity or the MCU fails.

The Android manifest enables cleartext for the ESP32's private local WebSocket
prototype. Do not expose an unencrypted/unauthenticated controller to public Wi-Fi.
Use TLS/authentication or another appropriate trust model for deployment outside
an isolated robot network. OctoBot targets Android only; the iOS/Swift project was removed.

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
flutter devices
flutter run -d <ANDROID_DEVICE_ID>
```

Tests are provided under `test/`. Run them in a local Flutter SDK installation;
this source package was prepared without a Flutter SDK in the execution environment.

## Android-only target

Only `flutter/android/` is maintained as a platform project. To avoid Flutter
launching the connected iPhone, use `flutter devices` and explicitly choose an
Android device/emulator ID with `flutter run -d <ANDROID_DEVICE_ID>`.

Flutter UI is written in Dart; the Android host uses Kotlin. The iOS Runner,
Swift sources and Xcode project are intentionally not tracked.
