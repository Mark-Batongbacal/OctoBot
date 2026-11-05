#include "ServoOutput.h"
#include "Config.h"
#include <Wire.h>
#include <cmath>

ServoOutput::ServoOutput() : pwm_(cfg::kPcaAddress, Wire) {}

bool ServoOutput::begin() {
  pinMode(cfg::kOutputEnablePin, OUTPUT);
  digitalWrite(cfg::kOutputEnablePin, HIGH);  // output DISABLED (OE active-high)
  Wire.begin(cfg::kServoSda, cfg::kServoScl, 100000);
  ready_ = pwm_.begin();
  if (ready_) pwm_.setPWMFreq(cfg::kServoPwmHz);
  return ready_;
}
void ServoOutput::disable() {
  digitalWrite(cfg::kOutputEnablePin, HIGH);
  enabled_ = false;
}
void ServoOutput::enable() {
  if (!ready_) return;
  digitalWrite(cfg::kOutputEnablePin, LOW);
  enabled_ = true;
}
void ServoOutput::pulse(uint8_t channel, float us) {
  if (!ready_) return;
  const uint16_t safe = static_cast<uint16_t>(roundf(
    fmaxf(static_cast<float>(cfg::kServoMinUs),
          fminf(static_cast<float>(cfg::kServoMaxUs), us))));
  pwm_.writeMicroseconds(channel, safe);
}
void ServoOutput::writeLeg(unsigned leg, float footHorizontal, float footLift) {
  if (!ready_ || !enabled_ || leg >= 8) return;
  const LegCalibration& cal = kLegCalibration[leg];
  pulse(cal.horizontalChannel, cal.horizontalNeutralUs +
        cal.horizontalSign * footHorizontal * cfg::kSwingUs);
  pulse(cal.verticalChannel, cal.verticalNeutralUs +
        cal.liftSign * footLift * cfg::kLiftUs);
}
