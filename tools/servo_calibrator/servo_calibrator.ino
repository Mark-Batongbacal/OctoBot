// STANDALONE BENCH SKETCH — NEVER USE WHILE THE SPIDER SUPPORTS ITS WEIGHT.
// Requires Adafruit PWM Servo Driver Library. One channel at a time, pulses
// restricted to 1250..1750 us until physical end stops are verified.
// GPIO27 must be connected through a normally-closed E-stop switch to GND.
// GPIO25 must be held LOW (bench-enable) to allow a requested test pulse.
// The PCA9685 OE line on GPIO26 MUST have a hardware pull-up to disable at boot.
#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>

Adafruit_PWMServoDriver pwm(0x40, Wire);
constexpr int OE = 26, ESTOP = 27, ARM = 25;
char lineBuffer[24];
size_t lineLength = 0;
uint32_t until = 0;

void allOff() {
  digitalWrite(OE, HIGH); // Disable outputs before reconfiguring channels.
  for (int i = 0; i < 16; ++i) pwm.setPWM(i, 0, 4096);
  until = 0;
}
void setup() {
  Serial.begin(115200);
  pinMode(OE, OUTPUT);
  digitalWrite(OE, HIGH);
  pinMode(ESTOP, INPUT_PULLUP);
  pinMode(ARM, INPUT_PULLUP);
  Wire.begin(21, 22, 100000);
  if (!pwm.begin()) {
    Serial.println("ERROR: PCA9685 missing. Leave output disabled.");
    return;
  }
  pwm.setPWMFreq(50);
  allOff();
  Serial.println("BENCH ONLY: enter CHANNEL,PULSE_US (example 0,1500)." );
  Serial.println("Test one unloaded servo at a time. Pulse lasts 1.5 seconds.");
}
void loop() {
  if (digitalRead(ESTOP) != LOW || digitalRead(ARM) != LOW) {
    if (until) allOff();
  } else if (until && (int32_t)(millis() - until) >= 0) {
    allOff();
  }
  while (Serial.available()) {
    const char c = (char)Serial.read();
    if (c == '\n' || c == '\r') {
      lineBuffer[lineLength] = '\0';
      int ch=-1, pulse=0;
      if (sscanf(lineBuffer, "%d,%d", &ch, &pulse) == 2 &&
          ch >= 0 && ch < 16 && pulse >= 1250 && pulse <= 1750 &&
          digitalRead(ESTOP) == LOW && digitalRead(ARM) == LOW) {
        allOff();
        pwm.writeMicroseconds(ch, (uint16_t)pulse);
        digitalWrite(OE, LOW);
        until = millis() + 1500;
        Serial.printf("Channel %d -> %d us for 1.5 s\n", ch, pulse);
      } else if (lineLength) Serial.println("Rejected. Check input, arm and E-stop.");
      lineLength=0;
    } else if (lineLength < sizeof(lineBuffer)-1) lineBuffer[lineLength++] = c;
    else lineLength=0;
  }
  delay(5);
}
