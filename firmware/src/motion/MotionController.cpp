#include "MotionController.h"
#include "Config.h"
#include <cmath>

bool MotionController::begin() {
  return driver_.begin();
}
void MotionController::land(uint32_t now) {
  if (!landing_) {
    landing_ = true;
    landingAt_ = now;
    for (int i=0;i<8;i++) landingLift_[i] = target_[i].lift;
  }
  const float t = fminf(1.0f, (now - landingAt_)
                       / static_cast<float>(cfg::kLandingTimeMs));
  for (int i=0;i<8;i++) {
    target_[i].lift = landingLift_[i] * (1.0f-t);
    driver_.writeLeg(i, target_[i].horizontal, target_[i].lift);
  }
  if (t >= 1.0f) landing_ = false;
}
void MotionController::tick(const Snapshot& state, uint32_t now) {
  // Critical hardware faults disable PWM. For communication/sensor timeouts,
  // keep servo holding torque and safely lower any lifted feet, if already armed.
  const bool hardFault = !driver_.ready() || !cfg::kServoCalibrationApproved ||
      !state.hardwareArmed || state.emergencyLatched;
  if (hardFault) {
    driver_.disable();
    outputsOn_ = false;
    walking_ = false;
    landing_ = false;
    lastAt_ = now;
    return;
  }
  if (!state.safeToDrive) {
    if (outputsOn_ && (walking_ || landing_)) land(now);
    walking_ = false;
    lastAt_ = now;
    return;
  }
  if (!outputsOn_) {
    // Physical chassis MUST be supported and calibrated before this is enabled.
    driver_.enable();
    outputsOn_ = true;
    for (int i=0;i<8;i++) {
      target_[i] = FootTarget{};
      driver_.writeLeg(i, 0, 0);
    }
    lastAt_ = now;
    return;
  }
  const bool moving = fabsf(state.appliedForward) > 0.01f ||
                      fabsf(state.appliedTurn) > 0.01f;
  if (!moving) {
    if (walking_ || landing_) {
      if (!landing_) landingAt_ = now;
      land(now);
    }
    walking_ = false;
    lastAt_ = now;
    return;
  }
  if (!walking_) {
    // Start a fresh gait only after any prior landing is completed.
    if (landing_) { land(now); return; }
    phase_ = 0.0f;
    currentGait_ = state.gait;
    walking_ = true;
  }
  if (currentGait_ != state.gait) {
    // Do not abruptly change lift schedules mid-stride.
    land(now);
    walking_ = false;
    return;
  }
  const uint32_t dt = now - lastAt_;
  lastAt_ = now;
  phase_ = fmodf(phase_ + fminf(static_cast<float>(dt), 80.0f) /
          GaitEngine::cycleMs(currentGait_,
              fminf(state.command.speed, cfg::kCommissioningSpeedCap)), 1.0f);
  for (int i=0;i<8;i++) {
    target_[i] = GaitEngine::sample(i, currentGait_, phase_,
                                   state.appliedForward, state.appliedTurn);
    driver_.writeLeg(i, target_[i].horizontal, target_[i].lift);
  }
}
