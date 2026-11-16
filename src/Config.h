#pragma once
#include <Arduino.h>

// Confirm ALL electrical connections and mechanical limits before changing
// kServoCalibrationApproved to true. Firmware ships locked by design.
namespace cfg {
constexpr bool kServoCalibrationApproved = false;
// TEMPORARY supervised bench mode. Does not bypass ARM, E-stop,
// PCA9685 detection, sensor, link timeout, or command watchdog.
// Autonomous gait remains blocked until calibration is approved.
constexpr bool kAllowUncalibratedManualTest = true;
constexpr float kUncalibratedTestSwingUs = 40.0f;
constexpr float kUncalibratedTestLiftUs = 40.0f;
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
constexpr float kCommissioningSpeedCap = 0.15f; // limited bench-test speed
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
// Physical identification numbers are 1-based (1..16); PCA9685 uses CH0..CH15.
// Assuming rows supplied front-to-rear: row 1 L1/R1, ..., row 4 L4/R4.
// For each pair, the first is assumed horizontal (hip), second vertical (knee).
// Confirm joint types and servo directions during supported off-ground calibration.
// KEEP logical order L1,L2,L3,L4,R1,R2,R3,R4 for existing gait calculations.
constexpr LegCalibration kLegCalibration[8] = {
  { 7,  6, 1500, 1500, +1, +1}, // L1 observed 8/7 => CH7/CH6
  { 3,  5, 1500, 1500, +1, +1}, // L2 observed 4/6 => CH3/CH5
  { 0,  1, 1500, 1500, +1, +1}, // L3 observed 1/2 => CH0/CH1
  { 4,  2, 1500, 1500, +1, +1}, // L4 observed 5/3 => CH4/CH2
  {13, 15, 1500, 1500, -1, -1}, // R1 observed 14/16 => CH13/CH15
  {12, 14, 1500, 1500, -1, -1}, // R2 observed 13/15 => CH12/CH14
  { 9,  8, 1500, 1500, -1, -1}, // R3 observed 10/9 => CH9/CH8
  {10, 11, 1500, 1500, -1, -1}, // R4 observed 11/12 => CH10/CH11
};
