#pragma once
#include <Arduino.h>
#include <Adafruit_PWMServoDriver.h>

// PCA9685 is touched ONLY by the Motion task (except initial begin from setup).
class ServoOutput {
 public:
  ServoOutput();
  bool begin();
  void enable();
  void disable();
  void writeLeg(unsigned leg, float footHorizontal, float footLift);
  bool ready() const { return ready_; }
 private:
  Adafruit_PWMServoDriver pwm_;
  bool ready_ = false;
  bool enabled_ = false;
  void pulse(uint8_t channel, float us);
};
