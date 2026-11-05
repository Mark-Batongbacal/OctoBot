/// Values are unknown until the ESP32 actually publishes telemetry.
/// No battery %, sensor readings, or robot state is simulated by the UI.
class RobotTelemetry {
  const RobotTelemetry({
    this.batteryVoltage,
    this.distanceCm,
    this.mode,
    this.gaitPhase,
    this.state,
    this.obstacle,
    this.receivedAt,
  });

  final double? batteryVoltage;
  final double? distanceCm;
  final String? mode;
  final String? gaitPhase;
  final String? state;
  final bool? obstacle;
  final DateTime? receivedAt;

  static double? _number(dynamic value) => switch (value) {
    num n => n.toDouble(),
    _ => null,
  };

  factory RobotTelemetry.fromJson(Map<String, dynamic> json) {
    return RobotTelemetry(
      batteryVoltage: _number(json['battery_voltage']),
      distanceCm: _number(json['distance_cm']),
      mode: json['mode'] is String ? json['mode'] as String : null,
      gaitPhase: json['gait_phase'] is String ? json['gait_phase'] as String : null,
      state: json['state'] is String ? json['state'] as String : null,
      obstacle: json['obstacle'] is bool ? json['obstacle'] as bool : null,
      receivedAt: DateTime.now(),
    );
  }
}
