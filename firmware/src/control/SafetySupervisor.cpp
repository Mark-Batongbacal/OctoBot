#include "SafetySupervisor.h"
#include "Config.h"
#include <cmath>

void SafetySupervisor::tick(uint32_t now, bool physicalStopClosed,
                            bool physicalArm, bool driverReady) {
  Snapshot s = state_.snapshot();
  // NC E-stop is active-high on break/press. It must be reopened only by
  // power cycle + separate mechanical E-stop reset; never via Flutter.
  if (!physicalStopClosed) emergencyLatched_ = true;
  const bool heartbeatFresh = s.connected &&
      (now - s.lastHeartbeatMs < cfg::kLinkTimeoutMs);
  const bool distanceFresh = s.sensorValid &&
      (now - s.sensorAtMs < cfg::kSensorStaleMs);
  const bool batterySafe = !cfg::kBatteryDividerInstalled ||
      (s.batteryKnown && s.batteryVoltage >= cfg::kLowBatteryVolts);
  const bool hardwareSafe = cfg::kServoCalibrationApproved && driverReady &&
      physicalArm && !emergencyLatched_ && heartbeatFresh &&
      distanceFresh && batterySafe;
  float forward = 0, turn = 0;
  Activity activity = Activity::Stopped;
  if (s.mode != previousMode_) {
    autoStep_ = AutoStep::Forward;
    attempts_ = 0;
    stepStarted_ = now;
    previousMode_ = s.mode;
  }
  if (!hardwareSafe) {
    activity = Activity::Fault;
  } else if (s.mode == Mode::Manual) {
    // Heartbeat alone NEVER refreshes motion authorization.
    if (s.lastDriveMs != 0 && now - s.lastDriveMs <= cfg::kCommandTimeoutMs) {
      forward = s.command.forward;
      turn = s.command.turn;
      if (s.obstacle && forward > 0) {
        forward = turn = 0;
        activity = Activity::Obstacle;
      } else if (fabsf(forward) > 0.01f || fabsf(turn) > 0.01f) {
        activity = Activity::Walking;
      } else activity = Activity::Standing;
    } else activity = s.obstacle ? Activity::Obstacle : Activity::Standing;
  } else {
    // Only one front sensor: turn slowly to scan, never reverse autonomously.
    if (autoStep_ == AutoStep::Forward && s.obstacle) {
      autoStep_ = AutoStep::Settle;
      stepStarted_ = now;
    }
    switch (autoStep_) {
      case AutoStep::Forward:
        forward = 0.25f;
        activity = Activity::Walking;
        break;
      case AutoStep::Settle:
        activity = Activity::Obstacle;
        if (now - stepStarted_ >= 400) {
          autoStep_ = AutoStep::Turn;
          stepStarted_ = now;
        }
        break;
      case AutoStep::Turn:
        // Slow on-the-spot rotation with an unknown flank; demo clear area only.
        turn = 0.22f;
        activity = Activity::Walking;
        if (now - stepStarted_ >= 850) {
          autoStep_ = AutoStep::Check;
          stepStarted_ = now;
        }
        break;
      case AutoStep::Check:
        activity = Activity::Standing;
        if (now - stepStarted_ >= 250) {
          if (!s.obstacle) {
            autoStep_ = AutoStep::Forward;
            attempts_ = 0;
          } else if (++attempts_ >= 6) {
            autoStep_ = AutoStep::Blocked;
          } else {
            autoStep_ = AutoStep::Turn;
          }
          stepStarted_ = now;
        }
        break;
      case AutoStep::Blocked:
        activity = Activity::Blocked;
        break;
    }
  }
  // A concurrent STOP/disconnect/sensor update invalidates the snapshot; the
  // state manager rejects this stale decision, preventing re-arming old input.
  state_.updateSafety(s.version, forward, turn, hardwareSafe, physicalArm,
                      emergencyLatched_, activity);
}
