import 'package:flutter_test/flutter_test.dart';
import 'package:octobot/core/robot_telemetry.dart';

void main() {
  test('missing telemetry is not replaced with fictional values', () {
    final reading = RobotTelemetry.fromJson({'type': 'telemetry'});
    expect(reading.distanceCm, isNull);
    expect(reading.batteryVoltage, isNull);
    expect(reading.mode, isNull);
    expect(reading.obstacle, isNull);
  });

  test('parses robot-reported values and gait state', () {
    final reading = RobotTelemetry.fromJson({
      'type': 'telemetry',
      'mode': 'manual',
      'gait_phase': 'A',
      'distance_cm': 32,
      'battery_voltage': 7.8,
      'obstacle': false,
    });
    expect(reading.mode, 'manual');
    expect(reading.gaitPhase, 'A');
    expect(reading.distanceCm, 32.0);
    expect(reading.batteryVoltage, 7.8);
    expect(reading.obstacle, isFalse);
  });
}
