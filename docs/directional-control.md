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

The physical identification numbers are **1–16**, but PCA9685 outputs are **CH0–CH15**. Assuming the supplied rows run front to rear (L1/R1 through L4/R4), and each pair is horizontal then vertical, the new assignments are:

| Physical leg | Identified horizontal / vertical | PCA9685 horizontal / vertical | Gait group |
| --- | --- | --- | --- |
| L1 | 8 / 7 | CH7 / CH6 | A |
| L2 | 4 / 6 | CH3 / CH5 | B |
| L3 | 1 / 2 | CH0 / CH1 | A |
| L4 | 5 / 3 | CH4 / CH2 | B |
| R1 | 14 / 16 | CH13 / CH15 | B |
| R2 | 13 / 15 | CH12 / CH14 | A |
| R3 | 10 / 9 | CH9 / CH8 | B |
| R4 | 11 / 12 | CH10 / CH11 | A |

This changes only the servo-to-leg configuration. The GaitEngine logical leg indices, reciprocal group alternation, wave order, and left/right steering remain unchanged. Verify hip/knee assumptions, front-to-rear orientation, servo neutral positions, sign directions, and physical safety before approving calibration.

Group **A = L1 R2 L3 R4**; Group **B = R1 L2 R3 L4**.
A swings as B supports, then B swings as A supports.
Wave fallback lifts one foot at a time, in this sequence:
**L1 R2 L3 R4 R1 L2 R3 L4**.

`kLegCalibration` neutrals and directions are still **unverified placeholders**.
For limited testing, `kAllowUncalibratedManualTest=true` now permits MANUAL
movement with `kServoCalibrationApproved=false`, provided the physical ARM,
E-stop, PCA9685, front distance sensor, Wi-Fi heartbeat and motion watchdog
requirements are satisfied. **Autonomous movement stays calibration-locked.**
Uncalibrated motion is limited to 40 microseconds of hip swing/lift and a 15%
gait speed cap. Place the robot securely off-ground, ensure its independent
servo power cutoff works, and keep clear of moving links. A 1500 microsecond
neutral is not guaranteed to be mechanically safe. Restore the test flag to
`false` once physical calibration is complete.

## Commands and motion authorization

The Flutter joystick and directional controls send the SAME existing
`drive` WebSocket shape every ~100ms while held:

```json
{"type":"drive","forward":0.65,"turn":0.35,"speed":0.35,"gait":"reciprocal"}
```

Releasing/canceling the gesture sends `{"type":"stop"}`; the ESP32
independently expires drive messages after 450ms and stops on link loss.
The Flutter app sends manual commands when connected with fresh manual-mode
telemetry; the ESP32 independently enforces physical ARM, E-stop, front sensor,
link heartbeat, command watchdog and calibration (except the temporary
limited manual test exception). An obstacle directly ahead blocks **positive
forward** requests but allows reverse or in-place turning *only while the
front sensor remains valid and all hardware safety conditions pass*.

ESP32 telemetry includes `applied_forward`, `applied_turn`, and
`speed_cap` in addition to the earlier safety fields. The firmware
limits commissioning speed to 15% even if Flutter requests 100%.

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
6. First use limited bench mode with the robot supported off-ground to
   establish the actual neutral positions and joint directions. Before
   floor-supported gait tests, approve calibration only after confirming
   every servo and turn the temporary test flag OFF.
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
