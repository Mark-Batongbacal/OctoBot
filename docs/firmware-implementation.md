# OctoBot ESP32 firmware — Arduino IDE

## Single upload entry point

**Open [`OctoBot.ino`](../OctoBot.ino) in Arduino IDE.** It calls
`octobotSetup()` / `octobotLoop()` in `src/RobotRuntime.cpp` and the
Arduino build compiles all supporting `.cpp` files under `src/`.
No PlatformIO configuration, external build tool or manual per-file upload
is needed. For ESP32 board/libraries/USB upload settings see
[the root README](../README.md).

## Files that perform the actual work

| File | Responsibility |
| --- | --- |
| `OctoBot.ino` | Arduino IDE's setup() and loop() entry points |
| `src/RobotRuntime.cpp` | FreeRTOS task startup, sensor/safety/motion/telemetry scheduling |
| `src/Config.h` | ESP32 pins, servo channel map, hardware calibration lock and limits |
| `src/GaitEngine.cpp` | Alternating reciprocal/wave leg trajectories and steering mathematics |
| `src/MotionController.cpp` | Motor gait transitions, neutral positions, landing |
| `src/ServoOutput.cpp` | I²C/PCA9685 driver, per-leg calibrated servo pulse mapping, OE |
| `src/RobotState.cpp` | Atomic control state, STOP arbitration, command safety versioning |
| `src/SafetySupervisor.cpp` | E-stop, ARM, sensor freshness, movement timeout and obstacle logic |
| `src/RobotNetwork.cpp` | ESP32 Wi-Fi access point, Flutter WebSocket /ws, JSON commands and telemetry |
| `src/DistanceSensor.cpp` | VL53L0X ranging and validity |
| `src/BatteryMonitor.cpp` | Optional correctly wired battery voltage monitor |
| `tools/servo_calibrator/servo_calibrator.ino` | Separate one-channel, timed, bench-only servo calibration sketch |

Task scheduling: SafetyTask (priority 5), SensorTask (4), MotionTask (3),
TelemetryTask (1); motion target updates every 20 ms, telemetry about every
200 ms. WebSocket callbacks update state but never write motor PWM directly.

## Leg choreography

Group A: L1, R2, L3, R4. Group B: R1, L2, R3, L4.
Reciprocal alternates A/B lift and swing. Wave lifts one leg at a time
in sequence L1, R2, L3, R4, R1, L2, R3, L4.
Positive forward drives forward; negative forward reverses the same gait.
Positive/negative turn steer right/left with opposing side strokes.
Combined forward+turn generates *curved diagonals*, not lateral strafing.
True sideways movement remains **unimplemented and unvalidated**.

## Safety and practical testing

`cfg::kServoCalibrationApproved` is **false** by default.
Therefore compiling/flashing this sketch **does not move any servos**.
Verify a functional independent servo-power E-stop, isolated UBEC positive
rails, all 16 neutral/limit/direction calibrations, load support, and valid
front VL53L0X readings before considering a local calibration unlock.
Do not bypass sensor/ARM/E-stop checks to test unsupported motion.

Software watchdogs: command expires after 450 ms; link after 1200 ms.
The front sensor blocks unsafe forward travel; a supervised manual reverse
or in-place turn can remain available while hardware/sensor checks are valid.
Autonomy uses only front sensing and is not safe for unbounded navigation.

## Verification performed by CI

- Arduino CLI compiles the **actual root `OctoBot.ino`**, using the
  pinned ESP32 Arduino core and libraries.
- The separate Arduino calibration `.ino` compiles independently.
- Host C++ unit tests in `tests/native_gait_test.cpp` validate gait math.
- Flutter analysis and widget/telemetry tests run.

Compilation does not establish safe leg geometry or confirmed physical gait.
