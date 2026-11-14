#pragma once
#include <Arduino.h>
#include <Wire.h>
#include <VL53L0X.h>

class DistanceSensor {
 public:
  bool begin();
  bool read(float& cm);  // bounded by 45 ms sensor timeout
 private:
  VL53L0X sensor_;
  bool ready_ = false;
};
