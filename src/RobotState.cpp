#include "RobotState.h"
#include "Config.h"

const char* modeName(Mode m) { return m == Mode::Manual ? "manual" : "autonomous"; }
const char* gaitName(Gait g) { return g == Gait::Reciprocal ? "reciprocal" : "wave"; }
const char* activityName(Activity a) {
  switch (a) {
    case Activity::Fault: return "fault";
    case Activity::Stopped: return "stopped";
    case Activity::Standing: return "standing";
    case Activity::Walking: return "walking";
    case Activity::Obstacle: return "obstacle";
    case Activity::Blocked: return "blocked";
  }
  return "fault";
}
RobotState::RobotState() { data_.calibrated = cfg::kServoCalibrationApproved; }
Snapshot RobotState::snapshot() {
  taskENTER_CRITICAL(&mux_);
  const Snapshot copy = data_;
  taskEXIT_CRITICAL(&mux_);
  return copy;
}
void RobotState::connected(uint32_t id, uint32_t now) {
  taskENTER_CRITICAL(&mux_);
  data_.clientId = id;
  ++data_.version;
  data_.connected = true;
  data_.lastHeartbeatMs = now;
  data_.lastDriveMs = 0;
  data_.mode = Mode::Manual;
  data_.command = DriveCommand{};
  data_.appliedForward = data_.appliedTurn = 0;
  taskEXIT_CRITICAL(&mux_);
}
void RobotState::disconnected(uint32_t id) {
  taskENTER_CRITICAL(&mux_);
  if (data_.clientId == id) {
    data_.connected = false;
    ++data_.version;
    data_.clientId = 0;
    data_.mode = Mode::Manual;
    data_.lastHeartbeatMs = data_.lastDriveMs = 0;
    data_.command = DriveCommand{};
    data_.appliedForward = data_.appliedTurn = 0;
    data_.safeToDrive = false;
  }
  taskEXIT_CRITICAL(&mux_);
}
void RobotState::heartbeat(uint32_t id, uint32_t now) {
  taskENTER_CRITICAL(&mux_);
  if (data_.connected && data_.clientId == id) {
    data_.lastHeartbeatMs = now;
    ++data_.version;
  }
  taskEXIT_CRITICAL(&mux_);
}
void RobotState::drive(uint32_t id, const DriveCommand& command, uint32_t now) {
  taskENTER_CRITICAL(&mux_);
  if (data_.connected && data_.clientId == id && data_.mode == Mode::Manual) {
    data_.command = command;
    ++data_.version;
    data_.gait = command.gait;
    data_.lastDriveMs = now;
  }
  taskEXIT_CRITICAL(&mux_);
}
void RobotState::changeMode(uint32_t id, Mode mode) {
  taskENTER_CRITICAL(&mux_);
  if (data_.connected && data_.clientId == id) {
    data_.mode = mode;
    ++data_.version;
    data_.command = DriveCommand{};
    data_.lastDriveMs = 0;
    data_.appliedForward = data_.appliedTurn = 0;
    data_.safeToDrive = false;
  }
  taskEXIT_CRITICAL(&mux_);
}
void RobotState::stop(uint32_t id) {
  taskENTER_CRITICAL(&mux_);
  if (id == 0 || (data_.connected && data_.clientId == id)) {
    data_.command.forward = data_.command.turn = 0.0f;
    ++data_.version;
    data_.lastDriveMs = 0;
    data_.appliedForward = data_.appliedTurn = 0;
    data_.safeToDrive = false;
    data_.mode = Mode::Manual; // stop also cancels autonomy
  }
  taskEXIT_CRITICAL(&mux_);
}
void RobotState::updateDistance(bool valid, float cm, uint32_t now) {
  taskENTER_CRITICAL(&mux_);
  data_.sensorValid = valid;
  ++data_.version;
  data_.sensorAtMs = now;
  if (valid) {
    data_.distanceCm = cm;
    if (cm <= cfg::kObstacleStopCm) data_.obstacle = true;
    else if (cm >= cfg::kObstacleClearCm) data_.obstacle = false;
  } else data_.obstacle = true;
  if (data_.obstacle && data_.appliedForward > 0) {
    data_.appliedForward = data_.appliedTurn = 0;
    data_.safeToDrive = false;
  }
  taskEXIT_CRITICAL(&mux_);
}
void RobotState::updateBattery(bool valid, float volts) {
  taskENTER_CRITICAL(&mux_);
  data_.batteryKnown = valid;
  ++data_.version;
  if (valid) data_.batteryVoltage = volts;
  taskEXIT_CRITICAL(&mux_);
}
bool RobotState::updateSafety(uint32_t expectedVersion, float forward, float turn,
                              bool permitted, bool armed, bool emergency, Activity activity) {
  taskENTER_CRITICAL(&mux_);
  if (expectedVersion != data_.version) {
    data_.safeToDrive = false;
    data_.appliedForward = data_.appliedTurn = 0;
    taskEXIT_CRITICAL(&mux_);
    return false;
  }
  data_.hardwareArmed = armed;
  data_.emergencyLatched = emergency;
  data_.safeToDrive = permitted;
  data_.appliedForward = permitted ? forward : 0;
  data_.appliedTurn = permitted ? turn : 0;
  data_.activity = activity;
  taskEXIT_CRITICAL(&mux_);
  return true;
}
void RobotState::phase(char value) {
  taskENTER_CRITICAL(&mux_);
  data_.gaitPhase = value;
  taskEXIT_CRITICAL(&mux_);
}
