#pragma once
#include <stdint.h>

enum class Mode : uint8_t { Manual, Autonomous };
enum class Gait : uint8_t { Reciprocal, Wave };
enum class Activity : uint8_t { Fault, Stopped, Standing, Walking, Obstacle, Blocked };

struct DriveCommand {
  float forward = 0.0f;
  float turn = 0.0f; // positive = right/clockwise (matches Flutter)
  float speed = 0.35f;
  Gait gait = Gait::Reciprocal;
};

struct Snapshot {
  Mode mode = Mode::Manual;
  Gait gait = Gait::Reciprocal;
  Activity activity = Activity::Fault;
  DriveCommand command{};
  float appliedForward = 0.0f;
  float appliedTurn = 0.0f;
  uint32_t version = 0; // incremented on every safety-relevant input
  uint32_t clientId = 0;
  uint32_t lastHeartbeatMs = 0;
  uint32_t lastDriveMs = 0;
  uint32_t sensorAtMs = 0;
  float distanceCm = 0.0f;
  float batteryVoltage = 0.0f;
  bool connected = false;
  bool sensorValid = false;
  bool obstacle = true; // unknown must be treated as obstructed
  bool batteryKnown = false;
  bool calibrated = false;
  bool hardwareArmed = false;
  bool emergencyLatched = false;
  bool safeToDrive = false;
  char gaitPhase = '-';
};

const char* modeName(Mode mode);
const char* gaitName(Gait gait);
const char* activityName(Activity state);
