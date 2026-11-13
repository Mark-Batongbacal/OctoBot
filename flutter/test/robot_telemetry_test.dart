import 'package:flutter_test/flutter_test.dart';
import 'package:octobot/core/robot_telemetry.dart';

void main() {
  test('unknown safety fields stay unknown and motion is locked', () {
    final reading = RobotTelemetry.fromJson({'type': 'telemetry'});
    expect(reading.distanceCm, isNull);
    expect(reading.batteryVoltage, isNull);
    expect(reading.mode, isNull);
    expect(reading.obstacle, isNull);
    expect(reading.calibrated, isNull);
    expect(reading.safeToDrive, isNull);
    expect(reading.motionAuthorized, isFalse);
  });

  test('parses actual movement and safety readiness', () {
    final reading = RobotTelemetry.fromJson({
      'type': 'telemetry',
      'mode': 'manual',
      'state': 'walking',
      'gait': 'reciprocal',
      'gait_phase': 'A',
      'distance_cm': 32,
      'battery_voltage': 7.8,
      'obstacle': false,
      'calibrated': true,
      'hardware_armed': true,
      'emergency_latched': false,
      'safe_to_drive': true,
      'applied_forward': 0.5,
      'applied_turn': -0.25,
      'speed_cap': 0.45,
    });
    expect(reading.mode, 'manual');
    expect(reading.gait, 'reciprocal');
    expect(reading.gaitPhase, 'A');
    expect(reading.distanceCm, 32.0);
    expect(reading.batteryVoltage, 7.8);
    expect(reading.appliedForward, 0.5);
    expect(reading.appliedTurn, -0.25);
    expect(reading.speedCap, 0.45);
    expect(reading.motionAuthorized, isTrue);
  });

  test('front obstacle alone does not disable safe reverse/turn mode', () {
    final reading = RobotTelemetry.fromJson({
      'calibrated': true,
      'hardware_armed': true,
      'emergency_latched': false,
      'safe_to_drive': true,
      'state': 'obstacle',
      'obstacle': true,
    });
    expect(reading.motionAuthorized, isTrue);
  });

  test('missing obstacle or robot activity never authorizes motion', () {
    final ready = {
      'calibrated': true,
      'hardware_armed': true,
      'emergency_latched': false,
      'safe_to_drive': true,
      'state': 'standing',
      'obstacle': false,
    };
    expect(RobotTelemetry.fromJson({...ready, 'obstacle': null}).motionAuthorized,
        isFalse);
    expect(RobotTelemetry.fromJson({...ready, 'state': null}).motionAuthorized,
        isFalse);
    expect(RobotTelemetry.fromJson({...ready, 'state': 'unknown'}).motionAuthorized,
        isFalse);
  });

  test('calibration, disarm, emergency and fault always block motion', () {
    final ready = {
      'calibrated': true,
      'hardware_armed': true,
      'emergency_latched': false,
      'safe_to_drive': true,
      'state': 'standing',
      'obstacle': false,
    };
    for (final override in [
      {'calibrated': false},
      {'hardware_armed': false},
      {'emergency_latched': true},
      {'safe_to_drive': false},
      {'state': 'fault'},
      {'state': 'blocked'},
    ]) {
      expect(RobotTelemetry.fromJson({...ready, ...override}).motionAuthorized,
          isFalse, reason: 'Should reject $override');
    }
  });
}
