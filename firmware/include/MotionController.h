#pragma once
#include <Arduino.h>
#include "ServoOutput.h"
#include "GaitEngine.h"
#include "Types.h"

class MotionController {
 public:
  bool begin();
  void tick(const Snapshot& state, uint32_t now);
  bool driverReady() const { return driver_.ready(); }
  char phaseLabel() const { return !walking_ ? '-' :
      (currentGait_ == Gait::Wave ? 'W' : (phase_ < .5f ? 'A' : 'B')); }
 private:
  ServoOutput driver_;
  FootTarget target_[8]{};
  float landingLift_[8]{};
  float phase_ = 0.0f;
  uint32_t lastAt_ = 0;
  uint32_t landingAt_ = 0;
  bool walking_ = false;
  bool landing_ = false;
  bool outputsOn_ = false;
  Gait currentGait_ = Gait::Reciprocal;
  void land(uint32_t now);
};
