# Archived implementation note

**The active and supported ESP32 upload target is now the Arduino IDE sketch `OctoBot.ino` in the repository root.** The older `firmware/` directory represents the previous PlatformIO staging layout and is not needed for Arduino IDE. See [README](../README.md), [directional control](directional-control.md), and [src/Config.h](../src/Config.h) for the current firmware and safety settings.

# ESP32 Arduino firmware implementation — OctoBot

## Status

The original implementation was built in `firmware/` and is now ported to the root Arduino IDE sketch and `src/`, organized into
hardware drivers, gait logic, shared state, safety supervisor, and WebSocket
communications. It is a **commissioning implementation**, with motor motion
locked in `Config.h` until the hardware is verified. Flutter files were not
modified by this phase; the JSON interface matches the preexisting controller.

## Software architecture

```text
Flutter Android (ws://192.168.4.1/ws)
    |
    v
ESP32 AsyncWebSocket  --> RobotState <---- VL53L0X sensor task (I2C1)
                           ^  ^
                           |  |
                FreeRTOS safety task (priority 5, E-stop notification)
                           |
                   Motion task (20ms)
                           |
                      GaitEngine
                           |
                  ServoOutput / PCA9685 (I2C0)
                           |
                        16 SG90
```

`TelemetryTask` sends robot-reported state every ~200ms. Network callbacks do
not write directly to servo hardware. `RobotState` rejects stale safety
calculations following a STOP or sensor update by comparing version counters.

## Movement plan

- Reciprocal A: L1/R2/L3/R4 swing, others stance.
- Reciprocal B: R1/L2/R3/L4 swing, others stance.
- Wave: same eight legs but one swing at a time.
- Hip (horizontal) sweeps for stance propulsion; lift (vertical) controls
  clearance. Mirrored servo signs remain **chassis-dependent placeholders**.
- Forward/turn mixing; diagonal means turning while walking, not strafe.

## Verification checklist (not yet completed)

- [ ] Confirm purchased ESP32 and VL53L0X breakout, servo board, leg linkage.
- [ ] Validate UBEC 4.8–5V output and motor stall demand under load.
- [ ] Assemble isolated positive servo rails and appropriate return wiring.
- [ ] Install E-stop physical cutoff and NC sensing loop; OE pull-up.
- [ ] Confirm center of mass supports reciprocal four-foot stance.
- [ ] Compile and upload with Arduino IDE for ESP32 Dev Module.
- [ ] Test all 16 servos individually without body load.
- [ ] Validate distance sensor timeouts, front-stop threshold and stale data.
- [ ] Measure stop-to-PWM response latency and body stabilization.
- [ ] Validate Flutter link/disconnect/mode switch and real telemetry.
- [ ] Run gait trial: wave first, reciprocal after full mechanical validation.

## Library documentation

- ESP32Async WebSocket path `/ws`: https://esp32async.github.io/ESPAsyncWebServer/setup/
- Pololu VL53L0X API and timeout: https://github.com/pololu/vl53l0x-arduino
- Adafruit PCA9685 and servo pulses: https://github.com/adafruit/Adafruit-PWM-Servo-Driver-Library
- Arduino ESP32 core: https://docs.espressif.com/projects/arduino-esp32/en/latest/
