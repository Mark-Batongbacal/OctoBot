import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'robot_telemetry.dart';

/// Phone-side transport only. Robot-side arbitration, watchdog and physical
/// emergency stopping MUST be implemented independently on the ESP32.
class RobotConnection extends ChangeNotifier {
  RobotConnection() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), _tick);
  }

  static const defaultEndpoint = 'ws://192.168.4.1/ws';

  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  late final Timer _timer;
  int _generation = 0;
  int _ticks = 0;
  bool _connecting = false;
  String? _error;
  String endpoint = defaultEndpoint;
  RobotTelemetry telemetry = const RobotTelemetry();
  final List<String> events = <String>[];
  double forward = 0;
  double turn = 0;
  double speed = 0.35;
  String gait = 'reciprocal';

  bool get connected => _socket?.readyState == WebSocket.open;
  bool get connecting => _connecting;
  String? get error => _error;
  bool get hasMotion => forward.abs() > 0.001 || turn.abs() > 0.001;
  bool get telemetryFresh => telemetry.receivedAt != null &&
      DateTime.now().difference(telemetry.receivedAt!) < const Duration(seconds: 2);
  /// The ESP32 decides whether its motors may move. A front obstacle only
  /// blocks *forward* drive, not deliberate reversing or turning in place.
  bool get manualArmed => connected && telemetryFresh &&
      telemetry.mode == 'manual' && telemetry.motionAuthorized;

  bool get frontBlocked => telemetryFresh && telemetry.obstacle == true;

  String get motionLockReason {
    if (!connected) return 'Connect to OctoBot to enable controls';
    if (!telemetryFresh) return 'Waiting for fresh ESP32 telemetry';
    if (telemetry.calibrated != true) return 'Servo calibration not approved on ESP32';
    if (telemetry.emergencyLatched != false) return 'E-stop active or not reported';
    if (telemetry.hardwareArmed != true) return 'Physical ARM switch is not enabled';
    if (telemetry.safeToDrive != true || telemetry.state == 'fault') {
      return 'Robot safety check failed (check front sensor and power)';
    }
    if (telemetry.mode != 'manual') return 'Request manual mode before driving';
    if (telemetry.state == 'blocked') return 'Robot reported motion blocked';
    return frontBlocked
        ? 'Front obstacle: reverse and turn only'
        : 'Drag to move · Release to stop';
  }

  void _log(String message) {
    final stamp = DateTime.now();
    final time = '${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}:${stamp.second.toString().padLeft(2, '0')}';
    events.insert(0, '$time  $message');
    if (events.length > 30) events.removeLast();
    notifyListeners();
  }

  Future<void> connect(String rawEndpoint) async {
    final uri = Uri.tryParse(rawEndpoint.trim());
    if (uri == null || !{'ws', 'wss'}.contains(uri.scheme) || uri.host.isEmpty) {
      _error = 'Enter a valid ws:// or wss:// address.';
      notifyListeners();
      return;
    }

    await disconnect();
    final generation = ++_generation;
    endpoint = uri.toString();
    _connecting = true;
    _error = null;
    notifyListeners();

    try {
      final socket = await WebSocket.connect(endpoint)
          .timeout(const Duration(seconds: 5));
      if (generation != _generation) {
        await socket.close();
        return;
      }
      _socket = socket;
      _connecting = false;
      telemetry = const RobotTelemetry();
      _subscription = socket.listen(
        _handleMessage,
        onError: (Object err) => _handleClose(socket, 'Connection error: $err'),
        onDone: () => _handleClose(socket, 'Connection closed.'),
        cancelOnError: true,
      );
      _log('WebSocket connected — awaiting ESP32 telemetry');
    } catch (err) {
      if (generation != _generation) return;
      _connecting = false;
      _error = 'Unable to connect. Check Wi-Fi and ESP32 endpoint.';
      _log('Connection failed: $err');
    }
  }

  void _handleMessage(dynamic data) {
    if (data is! String) return;
    try {
      final message = jsonDecode(data);
      if (message is! Map<String, dynamic>) return;
      switch (message['type']) {
        case 'telemetry':
          telemetry = RobotTelemetry.fromJson(message);
          // Never keep sending a forward target after obstacle detection.
          // Robot firmware independently applies the same restriction.
          if (telemetry.obstacle == true && forward > 0) {
            forward = 0;
            if (hasMotion) {
              _sendMotion();
            } else {
              _send({'type': 'stop'});
            }
          }
          notifyListeners();
          break;
        case 'event':
          _log(message['message'] is String
              ? message['message'] as String : 'Robot event received');
          break;
        case 'error':
          _log(message['message'] is String
              ? 'Robot: ${message['message']}' : 'Robot reported an error');
          break;
      }
    } on FormatException {
      _log('Ignored malformed ESP32 message');
    }
  }

  void _handleClose(WebSocket socket, String reason) {
    if (!identical(socket, _socket)) return;
    _socket = null;
    _subscription = null;
    forward = 0;
    turn = 0;
    telemetry = const RobotTelemetry();
    _log(reason);
  }

  void _send(Map<String, Object?> command) {
    final socket = _socket;
    if (socket == null || socket.readyState != WebSocket.open) return;
    try {
      socket.add(jsonEncode(command));
    } catch (err) {
      _log('Unable to send command: $err');
    }
  }

  void _sendMotion() {
    if (!connected) return;
    _send({
      'type': 'drive',
      'forward': double.parse(forward.toStringAsFixed(3)),
      'turn': double.parse(turn.toStringAsFixed(3)),
      'speed': double.parse(speed.toStringAsFixed(2)),
      'gait': gait,
    });
  }

  void _tick(Timer _) {
    if (!connected) return;
    if (hasMotion && !manualArmed) {
      stop();
      _log('Motion stopped: telemetry/mode no longer safe');
    } else if (hasMotion) {
      _sendMotion();
    }
    _ticks++;
    if (_ticks % 5 == 0) {
      _send({'type': 'heartbeat'});
      notifyListeners(); // Update stale telemetry/lock indicators.
    }
  }

  /// Joystick values: +forward means north, +turn means clockwise/right.
  void setMotion({required double nextForward, required double nextTurn}) {
    if (!manualArmed) return;
    final requestedForward = nextForward.clamp(-1.0, 1.0).toDouble();
    // The sole range sensor looks forward. Do not request travel into an
    // obstacle, but keep reverse/rotation commands available to escape.
    final newForward = frontBlocked && requestedForward > 0 ? 0.0 : requestedForward;
    final newTurn = nextTurn.clamp(-1.0, 1.0).toDouble();
    final wasMoving = hasMotion;
    forward = newForward.abs() < .10 ? 0 : newForward;
    turn = newTurn.abs() < .10 ? 0 : newTurn;
    if (!hasMotion && wasMoving) {
      stop();
    } else if (hasMotion) {
      _sendMotion();
      notifyListeners();
    }
  }

  void setSpeed(double nextSpeed) {
    speed = nextSpeed.clamp(0.10, 1.0).toDouble();
    if (hasMotion) _sendMotion();
    notifyListeners();
  }

  void setGait(String nextGait) {
    if (!{'reciprocal', 'wave'}.contains(nextGait)) return;
    gait = nextGait;
    if (hasMotion) _sendMotion();
    notifyListeners();
  }

  /// A software STOP request, not a physical power-cut emergency stop.
  void stop() {
    forward = 0;
    turn = 0;
    _send({'type': 'stop'});
    notifyListeners();
  }

  void requestMode(String requested) {
    if (!connected || !{'manual', 'autonomous'}.contains(requested)) return;
    if (requested == 'autonomous' && (!telemetryFresh || !telemetry.motionAuthorized)) {
      _log('Autonomous mode blocked: robot is not physically ready');
      return;
    }
    stop();
    _send({'type': 'mode', 'value': requested});
    _log('Requested $requested mode — waiting for robot acknowledgement');
  }

  Future<void> disconnect() async {
    _generation++;
    _connecting = false;
    stop();
    final socket = _socket;
    _socket = null;
    final subscription = _subscription;
    _subscription = null;
    telemetry = const RobotTelemetry();
    await subscription?.cancel();
    if (socket != null) {
      await socket.close();
      _log('Disconnected');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _generation++;
    _timer.cancel();
    final socket = _socket;
    _socket = null;
    _subscription?.cancel();
    _subscription = null;
    socket?.close();
    super.dispose();
  }
}
