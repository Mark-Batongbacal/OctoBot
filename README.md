# OctoBot

Eight-legged ESP32 + Flutter mobile control project.

- **Android mobile UI:** open [`flutter/`](flutter/README.md), run on Android.
- **ESP32 firmware:** open [`firmware/`](firmware/README.md) as a PlatformIO
  Arduino-framework project. FreeRTOS handles motion, safety and sensing.
- **Hardware installation:** follow the provisional pin/power instructions in
  [`firmware/README.md`](firmware/README.md) before connecting 16 SG90 servos.

The legacy `.ino` files at the repository root are placeholders from the initial
scaffold and **are not the active ESP32 controller**. Do not compile or upload
them to the robot. Hardware movement is locked by default until the actual
mechanical configuration, wiring and physical emergency stop are verified.

Current Flutter commands and firmware response shapes match the proposed
WebSocket protocol, but no completed hardware integration tests are claimed.
