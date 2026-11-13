# OctoBot — Arduino IDE + Flutter (Android)

**UPLOAD FILE:** [`OctoBot.ino`](OctoBot.ino) in the **repository root**.
This is now the **real ESP32 program**. Arduino IDE automatically compiles
the matching C++ modules under [`src/`](src/); do **not** upload
`.cpp` files individually and do **not** use PlatformIO.

> **Commissioning lock:** The program can boot, broadcast Wi-Fi and report
> telemetry, but it **cannot command servo motion** until the actual robot's
> joints, E-stop and power wiring have been verified. See `src/Config.h`.
> Do not disable the lock just to make the robot move.

## 1. Install Arduino IDE dependencies

1. Install **Arduino IDE 2.x**.
2. In **File → Preferences → Additional Boards Manager URLs**, add
   `https://espressif.github.io/arduino-esp32/package_esp32_index.json`.
3. In **Tools → Board → Boards Manager**, install **esp32 by Espressif
   Systems 2.0.17** (the pinned Arduino core version used in CI).
4. In **Library Manager**, install:
   - **Adafruit PWM Servo Driver Library** (3.0.3) and its dependencies
     (including Adafruit BusIO).
   - **VL53L0X** by Pololu (1.3.1).
   - **ArduinoJson** by Benoit Blanchon (7.4.3).
   - **ESP Async WebServer** by ESP32Async (3.6.0).
   - **AsyncTCP** by ESP32Async (3.3.2).
   
   If a pinned ESP32Async version is unavailable in Library Manager,
   install the tagged libraries from
   [ESPAsyncWebServer v3.6.0](https://github.com/ESP32Async/ESPAsyncWebServer/tree/v3.6.0)
   and [AsyncTCP v3.3.2](https://github.com/ESP32Async/AsyncTCP/tree/v3.3.2)
   into your Arduino libraries folder. Do not mix with obsolete me-no-dev
   or similarly named duplicate libraries.

## 2. Open and upload

1. Clone this repository **from the feature branch/PR until merged**, or
   extract its ZIP into a folder named **`OctoBot`** (the folder must match
   `OctoBot.ino`).
2. In Arduino IDE: **File → Open → OctoBot/OctoBot.ino**.
3. **Tools → Board → esp32 → ESP32 Dev Module** (for the planned ESP32 DevKit).
4. **Tools → Port →** your connected ESP32 USB port.
5. Click **Verify (✓)** and then **Upload (→)**.
6. Open **Serial Monitor at 115200 baud**. While uncalibrated, expect:
   `SAFE MODE: calibration not approved; NO SERVO MOVEMENT.`

The sketch's `setup()` / `loop()` are in `OctoBot.ino`. They call
`octobotSetup()` / `octobotLoop()` from `src/RobotRuntime.cpp`.
All FreeRTOS, walking, network, battery and sensor modules compile with
the sketch in Arduino IDE.

## 3. Flutter connection (after flashing)

1. Power ESP32 using a **verified regulated supply**, not the servo rail.
2. Join ESP32 Wi-Fi **OctoBot** on your Android phone.
   The current demo password is configured in `src/Config.h`; change it
   before operation near other users.
3. Launch the Flutter Android app from [`flutter/`](flutter/README.md).
4. In Connect, use `ws://192.168.4.1/ws`.
5. The app shows authentic ESP32 telemetry; motion controls remain disabled
   until firmware calibration and hardware safety checks permit movement.

**Supported control logic**: forward/backward, left/right turns and
curved forward/reverse diagonals using reciprocal or wave steps.
True sideways strafing is **not implemented**; the vertical-only
"bop-bop" idea has not been mechanically validated. See
[`docs/directional-control.md`](docs/directional-control.md).

## 4. Wiring and safety prerequisites

| ESP32 | Connection |
| --- | --- |
| GPIO21 / GPIO22 | PCA9685 SDA / SCL (3.3 V logic) |
| GPIO26 | PCA9685 OE; **external 10 kΩ pull-up** to 3.3 V |
| GPIO27 | NC E-stop sense to GND; open means STOP |
| GPIO25 | Physical ARM switch to GND; LOW = armed |
| GPIO32 / GPIO33 | VL53L0X SDA / SCL (separate I²C bus) |
| GPIO34 | Optional battery ADC through a proper voltage divider |

PCA9685 address: `0x40`, servo PWM: `50 Hz`.
Servo channels: L1 (0/1), L2 (2/3), L3 (4/5), L4 (6/7),
R1 (8/9), R2 (10/11), R3 (12/13), R4 (14/15).
Each pair is **horizontal/lift**.

**Physical E-stop must independently cut servo power**, even if the ESP32
crashes or Wi-Fi disconnects. The GPIO E-stop is only a sensing input.
The two independent 5 V UBEC positive outputs must **never be tied together**
through the PCA9685's common V+ header rail. Use isolated positive servo
distribution, correctly rated wiring/fusing, and common signal ground.
Start off-ground with linkages unloaded, check current draw and servo limits.

## 5. Calibrate before walking

In Arduino IDE, separately open
[`tools/servo_calibrator/servo_calibrator.ino`](tools/servo_calibrator/servo_calibrator.ino)
for **one-servo-at-a-time bench testing**. With ARM low, NC E-stop closed,
safe external servo power and the robot supported off-ground, enter
`0,1500` in Serial Monitor at 115200 baud. It sends one output for
1.5 seconds within 1250–1750 µs.

Verify each of the 16 servo neutral positions, horizontal forward sign,
lift sign and actual safe range. Enter the correct values into
[`src/Config.h`](src/Config.h) under `kLegCalibration`.
Confirm the complete robot can maintain a four-foot stance, physically
test the E-stop and confirm VL53L0X distance readings.
**Only after those checks** locally change
`cfg::kServoCalibrationApproved` to `true`.

The firmware still requires an armed physical switch, closed E-stop,
fresh range-sensor data, and live Flutter commands. It stops drive commands
after 450 ms of silence and the control link after 1200 ms.
The Flutter app's STOP is **not** a physical emergency cutoff.

## 6. Verification

GitHub Actions now compiles the root **Arduino sketch with arduino-cli**,
runs host gait-math unit tests and Flutter tests. Passing compilation is
**not proof of hardware balance, foot clearance or servo safety**.
A separate archived `firmware/` project contains the older PlatformIO
version, but it is not part of the active Arduino upload workflow.
