#pragma once
#include <Arduino.h>
#include "RobotState.h"

class SafetySupervisor {
 public:
  explicit SafetySupervisor(RobotState& state) : state_(state) {}
  void tick(uint32_t now, bool physicalStopClosed, bool physicalArm, bool driverReady);
 private:
  enum class AutoStep { Forward, Settle, Turn, Check, Blocked };
  RobotState& state_;
  AutoStep autoStep_ = AutoStep::Forward;
  Mode previousMode_ = Mode::Manual;
  uint32_t stepStarted_ = 0;
  uint8_t attempts_ = 0;
  bool emergencyLatched_ = false;
};
