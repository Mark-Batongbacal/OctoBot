#pragma once
#include <Arduino.h>

// Confirm ALL electrical connections and mechanical limits before changing
// kServoCalibrationApproved to true. Firmware ships locked by design.
namespace cfg {
constexpr bool kServoCalibrationApproved = false;
constexpr bool kBatteryDividerInstalled = false;
// Replace before using outside a private, isolated demonstration area.
constexpr char kApSsid[] = "OctoBot";
constexpr char kApPassword[] = "ChangeMe2026!"; // >=8 characters, change locally
constexpr uint8_t kPcaAddress = 0x40;
constexpr int kServoSda = 21, kServoScl = 22;
constexpr int kTofSda = 32, kTofScl = 33; // separate I2C bus
constexpr int kEmergencyPin = 27; // NC switch to GND: OPEN == E-STOP
constexpr int kArmPin = 25;       // physical arm switch to GND: LOW == ARM
constexpr int kOutputEnablePin = 26; // PCA9685 OE active HIGH = disabled
constexpr int kBatteryAdcPin = 34;
constexpr float kDividerTopOhms = 100000.0f;
constexpr float kDividerBottomOhms = 47000.0f;
constexpr float kLowBatteryVolts = 6.8f; // conservative threshold under load; verify pack
constexpr uint32_t kSensorPeriodMs = 50;
constexpr uint32_t kSensorStaleMs = 220;
constexpr uint32_t kCommandTimeoutMs = 450;
constexpr uint32_t kLinkTimeoutMs = 1200;
constexpr uint32_t kMotionPeriodMs = 20;
constexpr uint32_t kTelemetryPeriodMs = 200;
constexpr float kObstacleStopCm = 22.0f;
constexpr float kObstacleClearCm = 30.0f;
constexpr uint16_t kServoPwmHz = 50;
constexpr uint16_t kServoMinUs = 1250;
constexpr uint16_t kServoMaxUs = 1750;
constexpr float kSwingUs = 100.0f; // initial small stroke, tune only on a supported rig
constexpr float kLiftUs = 120.0f;  // initial small lift, tune only on a supported rig
constexpr uint32_t kLandingTimeMs = 360;
constexpr float kCommissioningSpeedCap = 0.45f; // raise only after stable load tests
constexpr uint32_t kMaxWebSocketPacketBytes = 256;
}

// Directions are INITIAL PLACEHOLDERS, not verified on the real chassis.
// Index = L1,L2,L3,L4,R1,R2,R3,R4; channels are separately mapped below.
struct LegCalibration {
  uint8_t horizontalChannel;
  uint8_t verticalChannel;
  int16_t horizontalNeutralUs;
  int16_t verticalNeutralUs;
  int8_t horizontalSign;
  int8_t liftSign;
};
constexpr LegCalibration kLegCalibration[8] = {
  {0, 1, 1500, 1500, +1, +1}, // L1
  {2, 3, 1500, 1500, +1, +1}, // L2
  {4, 5, 1500, 1500, +1, +1}, // L3
  {6, 7, 1500, 1500, +1, +1}, // L4
  {8, 9, 1500, 1500, -1, -1},// R1
  {10,11,1500, 1500, -1, -1},// R2
  {12,13,1500, 1500, -1, -1},// R3
  {14,15,1500, 1500, -1, -1} // R4
};
