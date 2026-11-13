# OctoBot directional movement — Flutter / ESP32 integration

## Current software capabilities

The active ESP32 firmware is the root Arduino IDE sketch `OctoBot.ino` plus
its compiled C++ modules in `src/`. Use the Android app in `flutter/`. The phone joins the ESP32's private Wi-Fi network and connects
to `ws://192.168.4.1/ws`.

| Flutter held direction | Robot command (forward, turn) | Intended behavior |
| --- | --- | --- |
| Forward | (+0.65, 0) | Reciprocal/wave forward steps |
| Reverse | (-0.65, 0) | Same gait, horizontal stance/swing reversed |
| Turn left | (0, -0.60) | Opposed left/right stance stroke, counterclockwise |
| Turn right | (0, +0.60) | Opposed left/right stance stroke, clockwise |
| Forward-left | (+0.65, -0.35) | Forward travel with leftward curvature |
| Forward-right | (+0.65, +0.35) | Forward travel with rightward curvature |
| Reverse-left | (-0.65, -0.35) | Reverse travel with leftward body rotation |
| Reverse-right | (-0.65, +0.35) | Reverse travel with rightward body rotation |
| Sideways/strafe | **NOT SUPPORTED** | Needs verified lateral foot trajectory and chassis geometry |

**Diagonal** means differential steering, *not straight-line diagonal
translation*. The experimental vertical-servo-only "bop-bop" idea has **not**
been proved to create lateral propulsion. The app does not issue a fake
sideways command. Four-feet-up motion must never be enabled until
center-of-gravity and contact support are verified on the real robot.

## Leg wiring and reciprocal groups

The channel mapping assumes CH0/1=L1 (horizontal/lift), CH2/3=L2,
CH4/5=L3, CH6/7=L4, CH8/9=R1, CH10/11=R2,
CH12/13=R3, CH14/15=R4.

Group **A = L1 R2 L3 R4**; Group **B = R1 L2 R3 L4**.
A swings as B supports, then B swings as A supports.
Wave fallback lifts one foot at a time, in this sequence:
**L1 R2 L3 R4 R1 L2 R3 L4**.

`kLegCalibration` neutral positions and sign orientations are still
placeholders. **Do not set `kServoCalibrationApproved=true` before
independently confirming every joint's center, safe endpoints, lift
direction, horizontal forward direction, and physical E-stop function.**
The app cannot authorize servo movement while calibration is locked.

## Commands and motion authorization

The Flutter joystick and directional controls send the SAME existing
`drive` WebSocket shape every ~100ms while held:

```json
{"type":"drive","forward":0.65,"turn":0.35,"speed":0.35,"gait":"reciprocal"}
```

Releasing/canceling the gesture sends `{"type":"stop"}`; the ESP32
independently expires drive messages after 450ms and stops on link loss.
The app checks fresh ESP32 telemetry for `calibrated`,
`hardware_armed`, `emergency_latched`, `safe_to_drive`, and manual mode
before allowing motion. An obstacle directly ahead blocks **positive
forward** requests but allows reverse or in-place turning *only while the
front sensor remains valid and all hardware safety conditions pass*.

ESP32 telemetry includes `applied_forward`, `applied_turn`, and
`speed_cap` in addition to the earlier safety fields. The firmware
limits commissioning speed to 45% even if Flutter requests 100%.

Autonomous navigation is **not** true route planning: the existing
front-only obstacle sensor triggers slow rotate-and-check. It cannot
verify side/rear clearance, cliffs, tipping, or traction.

## Physical commissioning checklist (mandatory)

1. Confirm independent, regulated UBEC positive servo rails, adequate
   ground distribution, stable ESP32 logic supply, and no V+ short
   between regulators (PCA9685 servo V+ buses are commonly shared).
2. Test physical servo-power cutoff independent of GPIO software.
   Verify NC E-stop GPIO27, ARM GPIO25, and OE GPIO26 pull-up.
3. With robot supported off-ground and linkages unloaded, use the
   single-channel calibrator to verify each servo's physical direction
   and limits. Update `src/Config.h` per joint.
4. Confirm a stable four-foot stance, foot clearance, current peaks,
   and that PWM-off does not let a leg collapse.
5. Validate real VL53L0X readings (GPIO32/33 second I2C bus).
   The firmware denies motion with missing or stale front sensor data.
6. **Only then** locally approve calibration and try the Flutter
   wave gait at minimum speed, then reciprocal, backward, turns,
   and curved diagonals. Keep the physical E-stop within reach.
7. Test STOP, release/cancel, app switching tabs, stale telemetry,
   WebSocket disconnect, E-stop and obstacle behavior with the robot
   safely supported before any ground-supported walking.

## Verification scope

- Pure C++ host gait tests verify pair grouping, wave ordering,
  forward/reverse symmetry, turns, and curved diagonal differential drive.
- Flutter tests verify telemetry parsing, unsafe-state lockouts, and
  the offline control screen.
- No actual ESP32 flash, SG90 movement measurement, battery current test,
  Wi-Fi latency test, or terrain test has been completed by these changes.

Use `flutter test` and `flutter analyze` in `flutter/`;
Arduino IDE **Verify / Upload** on `OctoBot.ino`;
and the native gait command in the repository README.
