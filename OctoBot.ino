/*
  OCTOBOT — ARDUINO IDE ESP32 CONTROLLER

  OPEN THIS FILE IN ARDUINO IDE and select "ESP32 Dev Module".
  Arduino IDE automatically compiles this sketch plus every .cpp/.h
  under its src/ directory. Do NOT upload each file individually.

  The integrated controller runs FreeRTOS tasks for:
   - PCA9685 servo output and reciprocal/wave gait
   - ESP32 Wi-Fi + Flutter WebSocket control
   - VL53L0X front-distance sensor and E-stop/ARM safety
   - live robot telemetry

  Safety: motors remain LOCKED until each servo's actual neutral,
  swing/lift direction, current limits and physical E-stop are verified.
  The lock is cfg::kServoCalibrationApproved in src/Config.h.
  A Flutter STOP is not a physical emergency power cutoff.

  Wiring: see README.md.
*/
#include <Arduino.h>
#include "src/RobotRuntime.h"

void setup() {
  octobotSetup();
}

void loop() {
  octobotLoop();
}
