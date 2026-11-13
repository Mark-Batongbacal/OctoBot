# OctoBot ESP32 firmware (Arduino framework + FreeRTOS)

**Commissioning build — actuator output is intentionally LOCKED.** No hardware
has been connected or validated through this GitHub change. Do not change
`cfg::kServoCalibrationApproved` until the mechanics, wiring and emergency power
cutoff have been tested on the physical spider.

## What is implemented

- Exact **eight-leg reciprocal alternating-tetrapod gait**:
  - Swing A: **L1, R2, L3, R4**; ground: R1, L2, R3, L4.
  - Swing B: **R1, L2, R3, L4**; ground: L1, R2, L3, R4.
  - Pairs across each row counteract each other. This is *different* from the
    cosmetic **blue** pairs (1,3) / **orange** pairs (2,4) in Flutter.
- Slow **wave gait** as a backup: lift only one foot at a time.
- Forward/reverse, clockwise/counterclockwise turns and curved diagonals using
  forward/turn mixing. **Sideways strafing is not guaranteed** with 2 DOF/leg.
- `SafetyTask` (priority 5), `SensorTask` (4), `MotionTask` (3), asynchronous
  Wi-Fi/WebSocket network callbacks, and `TelemetryTask` (1).
- FreeRTOS task notification from E-stop GPIO interruption, NC safety loop,
  physical arming input, command expiry, link heartbeat expiry, front-obstacle
  threshold with hysteresis, distance timeout, optional LiPo voltage readings.
- Conservative autonomous forward / pause / slow turn / scan / retry / blocked
  state machine. **Only front range sensing: do not use near edges, people or
  in confined spaces; no autonomous reverse.**
- ESP32 SoftAP, `ws://192.168.4.1/ws` and Flutter-compatible JSON messages.

For the compatible Flutter commands and exact hold-to-drive direction map,
see [directional control and commissioning](../docs/directional-control.md).
The physical robot must be calibrated before it can move. **Sideways strafing
is not an implemented capability** and cannot be inferred from vertical-only
rocking.

## Build with PlatformIO

The maintainable Arduino implementation is `firmware/src/*.cpp`, not a single
`.ino` file. PlatformIO uses the **Arduino framework** for ESP32 and FreeRTOS
underneath it. The old `.ino` files at repository root are legacy placeholders;
**do not upload them** as the robot's controller.

1. Open the repository's **`firmware/`** directory as a PlatformIO project in
   VS Code with the PlatformIO extension installed.
2. Check `include/Config.h` for board pins, calibration and Wi-Fi password.
3. Build with `pio run -e esp32dev`; USB upload `pio run -e esp32dev -t upload`;
   serial monitor `pio device monitor -b 115200`.
4. On first flash, expect `SAFE MODE: calibration not approved; NO SERVO MOVEMENT.`
   Connect an Android phone to **OctoBot** Wi-Fi, then in Flutter use
   `ws://192.168.4.1/ws`. You should see real telemetry but a **fault/locked**
   gait state until physical commissioning is completed.
5. Change the example SoftAP password in local configuration before using a
   public/shared environment. This is an **isolated LAN prototype**, not an
   authenticated Internet-safe control system.

### Libraries (pinned in `platformio.ini`)

- [Adafruit PCA9685 PWM Servo Driver 3.0.3](https://github.com/adafruit/Adafruit-PWM-Servo-Driver-Library)
- [Pololu VL53L0X 1.3.1](https://github.com/pololu/vl53l0x-arduino)
- [ArduinoJson 7.4.3](https://arduinojson.org/v7/)
- [ESP32Async ESPAsyncWebServer 3.6.0 and AsyncTCP 3.3.2](https://github.com/ESP32Async/ESPAsyncWebServer)
- [PlatformIO Espressif32 6.13.0, Arduino ESP32 2.0.17](https://docs.platformio.org/en/latest/platforms/espressif32.html)

These versions are chosen based on published APIs. PlatformIO firmware compilation
and flashing **must still be run on an ESP32-capable development machine**.

## Pin plan — ESP32 DevKit / WROOM-32 (provisional)

| ESP32 pin | Function | Important detail |
|---|---|---|
| GPIO21 | PCA9685 SDA | PCA logic to 3.3V, common ground |
| GPIO22 | PCA9685 SCL | separate I2C bus 0 |
| GPIO32 | VL53L0X SDA | I2C bus 1; check breakout voltage ratings |
| GPIO33 | VL53L0X SCL | I2C bus 1 |
| GPIO26 | PCA9685 OE | HIGH = signal disabled; external pullup REQUIRED |
| GPIO27 | **Normally-closed E-stop sense** | to ground when healthy; opens on pressed/broken loop |
| GPIO25 | Physical ARM switch | to ground to arm; default pullup = disarmed |
| GPIO34 | Battery ADC (optional) | 100k/47k divider, never direct 2S battery |

**E-stop hardware:** The GPIO E-stop is a software *sense*. Use a correctly rated
separate physical cutoff for servo power that remains effective if ESP32 hangs.
An emergency hard cut will lose SG90 holding torque; mechanically support the
robot and keep testing clear of fingers/pinch points. GPIO alone is not a
functional-safety guarantee.

**Power distribution:** 2S LiPo XT60 -> protected distribution -> independent
regulators: 8A UBEC A for eight **LEFT** servo positive wires, 8A UBEC B for
8 **RIGHT** servo positive wires. Mini560 powers the ESP32/control side subject
to its input voltage and current specs. Your two terminal blocks can distribute
the separate servo V+ banks **if their poles/rating allow it**; use separately
rated return/ground distribution. A typical PCA9685 board shares all 16 V+
headers, so **do not connect both UBECs to its V+**. Connect PWM signal wires to
the PCA9685, each servo V+ to its own external UBEC bank, and join grounds at a
suitable low-impedance reference point. Never put servo motor currents through
a matrix/perfboard or ESP32 pins. Use proper fuse protection, wire gauges,
physical switch and LiPo-safe charging procedures.

## PCA9685 channel map

| Leg | Horizontal | Lift |
|---|---:|---:|
| L1 | 0 | 1 |
| L2 | 2 | 3 |
| L3 | 4 | 5 |
| L4 | 6 | 7 |
| R1 | 8 | 9 |
| R2 | 10 | 11 |
| R3 | 12 | 13 |
| R4 | 14 | 15 |

Angles are not hardcoded because the mechanics are unknown: `kLegCalibration`
contains **placeholder** per-leg neutral microseconds and servo directions.
Safe pulse clamp initially 1250–1750 µs. `cfg::kSwingUs` and `cfg::kLiftUs` are
*small, initial* stroke amplitudes, not validated gait values. PCA9685 outputs
remain gated during startup; individual calibrated neutral pulses are written
before OE is enabled. A supported, unloaded first-arm test is still mandatory.
A firmware commissioning speed cap of 45% applies even if Flutter selects
100%; increase `kCommissioningSpeedCap` only after stability/load tests.

### Calibration before enabling movement

1. Validate battery, both UBEC output voltages (SG90 variant dependent),
   Mini560 output, current capacity and common ground **without servos**.
2. With the chassis securely supported and all high-torque linkages unloaded,
   use standalone **`tools/servo_calibrator/servo_calibrator.ino` in Arduino IDE**.
   Send e.g. `0,1500` over 115200 serial with physical ARM held low and NC
   safety loop closed. It drives **one channel only**, for **1.5 seconds**.
3. Mechanically verify all 16 neutral positions, axis directions and individual
   endpoints. Update eight `kLegCalibration` records individually; check whether
   real SG90 units accept the selected pulse range safely.
4. Confirm supported standing posture, joint linkages, center of gravity, feet
   friction and four-foot support. **Do not enable full alternating gait if the
   robot cannot support itself safely on those four legs.**
5. Implement / validate physical stop (power cutoff), then set
   `cfg::kServoCalibrationApproved = true` locally. GPIO25 still requires an
   intentional physical arm and GPIO27 closed E-stop loop.
6. First walking tests: **wave gait** at 10% speed, on a protected low-friction
   testing surface, then slower reciprocal gait, THEN turns and autonomy.

The 2S 2200mAh LiPo and balance charger, two UBECs, Mini560, terminal blocks,
and matrix board have assigned roles; additional ESP32, VL53L0X, cutoff switch,
fuses, and appropriately rated wiring are needed to complete the design.

## Protocol with Flutter

| Direction | Example |
|---|---|
| Flutter -> ESP32 | `{"type":"heartbeat"}` every 500 ms |
| Flutter -> ESP32 | `{"type":"mode","value":"manual"}` |
| Flutter -> ESP32 | `{"type":"mode","value":"autonomous"}` |
| Flutter -> ESP32 | `{"type":"drive","forward":0.5,"turn":-0.25,"speed":0.35,"gait":"reciprocal"}` |
| Flutter -> ESP32 | `{"type":"stop"}` (also cancels autonomy) |
| ESP32 -> Flutter | `{"type":"telemetry","mode":"manual","state":"fault","gait_phase":"-","distance_cm":null,"battery_voltage":null,"obstacle":true}` |

Flutter sends active movement ~100ms, heartbeat ~500ms; commands expire
independently after 450ms without new drive messages. Link expires at 1200ms.
Only one WebSocket controller may connect at a time. STOP zeroes motor command
in shared state immediately; the Motion task applies the next safe target.

No fake sensor/battery readings are inserted. The optional battery divider is
**disabled until installed** (`kBatteryDividerInstalled=false`); no guessed
remaining percentage or time is reported. A lone front VL53L0X cannot observe
side/rear collisions, terrain height, tipping or fall hazards.

## Non-embedded host test

From repository root:

```sh
c++ -std=c++17 -Wall -Wextra -Ifirmware/include \
  firmware/src/motion/GaitEngine.cpp firmware/test/native_gait_test.cpp \
  -o /tmp/octobot-gait-test && /tmp/octobot-gait-test
```

This validates **gait timing and reciprocal grouping only**, not PlatformIO
buildability, motor mechanics, power, sensor behavior or emergency-stop latency.

## Software modules

- `GaitEngine` — pure trajectory math for reciprocal/wave, easy host testing.
- `MotionController` — sole owner of `ServoOutput`/PCA9685, landing transitions.
- `DistanceSensor`, `BatteryMonitor` — hardware acquisition, sensor timeouts.
- `RobotState` — short FreeRTOS critical sections, stale-decision protection.
- `SafetySupervisor` — motion authorization, physical interlocks, autonomy FSM.
- `RobotNetwork` — AsyncWebSocket `/ws`, commands, telemetry, one client.
- `main.cpp` — task creation and GPIO interrupt, not monolithic robot logic.

**Firmware is designed for hardware commissioning, not verified autonomous
operation. Do not test with human contact or in uncontrolled environments.**
