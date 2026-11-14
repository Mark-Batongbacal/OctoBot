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
  if (ready_) {
    pwm_.setPWMFreq(cfg::kServoPwmHz);
    // Start hard-off. PWM is not exposed to servos before neutral is staged.
    for (uint8_t channel = 0; channel < 16; ++channel) {
      pwm_.setPWM(channel, 0, 4096);
    }
  }
  return ready_;
}
void ServoOutput::disable() {
  digitalWrite(cfg::kOutputEnablePin, HIGH);
  enabled_ = false;
}
void ServoOutput::enable() {
  if (!ready_ || enabled_) return;
  // Load each CALIBRATED neutral pulse while the OE pin is still HIGH.
  // Opening the gate before staging PWM risks an uncontrolled first target.
  for (unsigned leg = 0; leg < 8; ++leg) {
    const LegCalibration& cal = kLegCalibration[leg];
    pulse(cal.horizontalChannel, cal.horizontalNeutralUs);
    pulse(cal.verticalChannel, cal.verticalNeutralUs);
  }
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
