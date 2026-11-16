#pragma once
#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/portmacro.h>
#include "Types.h"

// Only short copies/assignments under the critical section; no I/O, heap,
// network operations, or motor commands may occur while holding the lock.
class RobotState {
 public:
  RobotState();
  Snapshot snapshot();
  void connected(uint32_t id, uint32_t now);
  void disconnected(uint32_t id);
  void heartbeat(uint32_t id, uint32_t now);
  void drive(uint32_t id, const DriveCommand& command, uint32_t now);
  void changeMode(uint32_t id, Mode mode);
  void stop(uint32_t id = 0);
  void updateDistance(bool valid, float cm, uint32_t now);
  void updateBattery(bool valid, float volts);
  bool updateSafety(uint32_t expectedVersion, float forward, float turn, bool permitted,
                    bool armed, bool emergency, Activity state);
  void phase(char value);
 private:
  portMUX_TYPE mux_ = portMUX_INITIALIZER_UNLOCKED;
  Snapshot data_{};
};
