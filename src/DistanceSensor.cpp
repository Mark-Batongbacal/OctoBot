#include "DistanceSensor.h"
#include "Config.h"

bool DistanceSensor::begin() {
  Wire1.begin(cfg::kTofSda, cfg::kTofScl, 100000);
  sensor_.setBus(&Wire1);
  sensor_.setTimeout(45);
  ready_ = sensor_.init();
  if (ready_) {
    sensor_.setMeasurementTimingBudget(33000);
    sensor_.startContinuous(cfg::kSensorPeriodMs);
  }
  return ready_;
}
bool DistanceSensor::read(float& cm) {
  if (!ready_) return false;
  const uint16_t mm = sensor_.readRangeContinuousMillimeters();
  if (sensor_.timeoutOccurred() || mm == 0 || mm == 65535) return false;
  cm = mm / 10.0f;
  return cm > 0 && cm <= 200.0f;
}
