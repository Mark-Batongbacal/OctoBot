#include "BatteryMonitor.h"
#include "Config.h"

void BatteryMonitor::begin() {
  if (cfg::kBatteryDividerInstalled) {
    pinMode(cfg::kBatteryAdcPin, INPUT);
    analogSetPinAttenuation(cfg::kBatteryAdcPin, ADC_11db);
  }
}
bool BatteryMonitor::sample(float& volts) {
  if (!cfg::kBatteryDividerInstalled) return false;
  uint32_t sumMv = 0;
  for (int i = 0; i < 4; ++i) sumMv += analogReadMilliVolts(cfg::kBatteryAdcPin);
  const float adcVolts = (sumMv / 4.0f) / 1000.0f;
  volts = adcVolts * (cfg::kDividerTopOhms + cfg::kDividerBottomOhms)
          / cfg::kDividerBottomOhms;
  return volts > 4.0f && volts < 9.0f;
}
