#include <Arduino.h>
#include "RobotRuntime.h"
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include "Config.h"
#include "RobotState.h"
#include "ServoOutput.h"
#include "MotionController.h"
#include "DistanceSensor.h"
#include "BatteryMonitor.h"
#include "RobotNetwork.h"
#include "SafetySupervisor.h"

namespace {
RobotState robot;
DistanceSensor distanceSensor;
BatteryMonitor batteryMonitor;
MotionController motion;
RobotNetwork network(robot);
SafetySupervisor safety(robot);
TaskHandle_t safetyHandle = nullptr;
volatile bool emergencyIrqLatched = false;
bool servoDriverReady = false;

void IRAM_ATTR onEmergencyInterrupt() {
  emergencyIrqLatched = true;
  if (safetyHandle) {
    BaseType_t awoken = pdFALSE;
    vTaskNotifyGiveFromISR(safetyHandle, &awoken);
    if (awoken == pdTRUE) portYIELD_FROM_ISR();
  }
}

void safetyTask(void*) {
  for (;;) {
    // Timed wakeup also covers missing interrupts / disconnected switches.
    ulTaskNotifyTake(pdTRUE, pdMS_TO_TICKS(20));
    const bool stopClosed = !emergencyIrqLatched &&
        digitalRead(cfg::kEmergencyPin) == LOW;
    const bool armed = digitalRead(cfg::kArmPin) == LOW;
    safety.tick(millis(), stopClosed, armed, servoDriverReady);
  }
}
void sensorTask(void*) {
  bool initialized = distanceSensor.begin();
  uint32_t lastRetry = millis();
  batteryMonitor.begin();
  uint32_t lastBattery = 0;
  TickType_t wake = xTaskGetTickCount();
  for (;;) {
    const uint32_t now = millis();
    if (!initialized && now - lastRetry >= 2000) {
      initialized = distanceSensor.begin();
      lastRetry = now;
    }
    float cm = 0.0f;
    const bool valid = initialized && distanceSensor.read(cm);
    robot.updateDistance(valid, cm, millis());
    if (now - lastBattery >= 500) {
      float volts = 0.0f;
      const bool voltageValid = batteryMonitor.sample(volts);
      robot.updateBattery(voltageValid, volts);
      lastBattery = now;
    }
    vTaskDelayUntil(&wake, pdMS_TO_TICKS(cfg::kSensorPeriodMs));
  }
}
void motionTask(void*) {
  TickType_t wake = xTaskGetTickCount();
  for (;;) {
    const Snapshot snapshot = robot.snapshot();
    motion.tick(snapshot, millis());
    robot.phase(snapshot.activity == Activity::Walking ? motion.phaseLabel() : '-');
    vTaskDelayUntil(&wake, pdMS_TO_TICKS(cfg::kMotionPeriodMs));
  }
}
void telemetryTask(void*) {
  TickType_t wake = xTaskGetTickCount();
  uint32_t lastCleanup = 0;
  for (;;) {
    network.telemetry(robot.snapshot());
    if (millis() - lastCleanup >= 2000) {
      network.housekeeping();
      lastCleanup = millis();
    }
    vTaskDelayUntil(&wake, pdMS_TO_TICKS(cfg::kTelemetryPeriodMs));
  }
}
void failClosed(const char* reason) {
  digitalWrite(cfg::kOutputEnablePin, HIGH);
  Serial.printf("FIRMWARE FAULT: %s. Servo outputs remain disabled.\n", reason);
  while (true) delay(1000);
}
} // namespace

void octobotSetup() {
  Serial.begin(115200);
  pinMode(cfg::kOutputEnablePin, OUTPUT);
  digitalWrite(cfg::kOutputEnablePin, HIGH);
  pinMode(cfg::kEmergencyPin, INPUT_PULLUP); // NC closed to GND
  pinMode(cfg::kArmPin, INPUT_PULLUP); // hold LOW to authorize motion
  servoDriverReady = motion.begin();
  if (!servoDriverReady) Serial.println("PCA9685 not detected; motion disabled.");
  if (!network.begin()) failClosed("ESP32 access point failed");
  if (digitalRead(cfg::kEmergencyPin) == HIGH) emergencyIrqLatched = true;
  if (xTaskCreatePinnedToCore(safetyTask, "Safety", 4096, nullptr, 5,
                              &safetyHandle, 1) != pdPASS)
    failClosed("Safety task allocation");
  attachInterrupt(digitalPinToInterrupt(cfg::kEmergencyPin),
                  onEmergencyInterrupt, RISING);
  if (xTaskCreatePinnedToCore(sensorTask, "Sensor", 4096, nullptr, 4,
                              nullptr, 1) != pdPASS ||
      xTaskCreatePinnedToCore(motionTask, "Motion", 4096, nullptr, 3,
                              nullptr, 1) != pdPASS ||
      xTaskCreatePinnedToCore(telemetryTask, "Telemetry", 6144, nullptr, 1,
                              nullptr, 0) != pdPASS)
    failClosed("Worker task allocation");
  if (!cfg::kServoCalibrationApproved)
    Serial.println("SAFE MODE: calibration not approved; NO SERVO MOVEMENT.");
}

void octobotLoop() {
  // Arduino's loopTask remains idle; all control runs in dedicated FreeRTOS tasks.
  delay(1000);
}
