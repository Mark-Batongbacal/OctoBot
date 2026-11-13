/// Telemetry is authoritative only when fresh; unknown fields remain null.
/// Physical motion authorization is enforced independently on the ESP32.
class RobotTelemetry {
  const RobotTelemetry({
    this.batteryVoltage,
    this.distanceCm,
    this.mode,
    this.gait,
    this.gaitPhase,
    this.state,
    this.obstacle,
    this.calibrated,
    this.hardwareArmed,
    this.emergencyLatched,
    this.safeToDrive,
    this.appliedForward,
    this.appliedTurn,
    this.speedCap,
    this.receivedAt,
  });

  final double? batteryVoltage;
  final double? distanceCm;
  final String? mode;
  final String? gait;
  final String? gaitPhase;
  final String? state;
  final bool? obstacle;
  final bool? calibrated;
  final bool? hardwareArmed;
  final bool? emergencyLatched;
  final bool? safeToDrive;
  final double? appliedForward;
  final double? appliedTurn;
  final double? speedCap;
  final DateTime? receivedAt;

  bool get motionAuthorized => calibrated == true &&
      hardwareArmed == true && emergencyLatched == false &&
      safeToDrive == true && state != 'fault' && state != 'blocked';

  static double? _number(dynamic value) => switch (value) {
    num n => n.toDouble(),
    _ => null,
  };

  factory RobotTelemetry.fromJson(Map<String, dynamic> json) {
    return RobotTelemetry(
      batteryVoltage: _number(json['battery_voltage']),
      distanceCm: _number(json['distance_cm']),
      mode: json['mode'] is String ? json['mode'] as String : null,
      gait: json['gait'] is String ? json['gait'] as String : null,
      gaitPhase: json['gait_phase'] is String ? json['gait_phase'] as String : null,
      state: json['state'] is String ? json['state'] as String : null,
      obstacle: json['obstacle'] is bool ? json['obstacle'] as bool : null,
      calibrated: json['calibrated'] is bool ? json['calibrated'] as bool : null,
      hardwareArmed: json['hardware_armed'] is bool ? json['hardware_armed'] as bool : null,
      emergencyLatched: json['emergency_latched'] is bool ? json['emergency_latched'] as bool : null,
      safeToDrive: json['safe_to_drive'] is bool ? json['safe_to_drive'] as bool : null,
      appliedForward: _number(json['applied_forward']),
      appliedTurn: _number(json['applied_turn']),
      speedCap: _number(json['speed_cap']),
      receivedAt: DateTime.now(),
    );
  }
}
