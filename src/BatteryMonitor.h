#pragma once
#include <Arduino.h>

class BatteryMonitor {
 public:
  void begin();
  bool sample(float& volts);
};
