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
  int _nextPressId = 0;
  int? _activePressId;
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
  /// Manual mode and a fresh link enable reverse and pivot controls.
  /// The front ultrasonic sensor only restricts FORWARD movement.
  bool get manualArmed =>
      connected && telemetryFresh && telemetry.mode == 'manual';

  bool get forwardBlocked =>
      !telemetryFresh ||
      telemetry.sensorValid != true ||
      telemetry.safetyBlocked != false;

  bool get frontBlocked => forwardBlocked;

  String get motionLockReason {
    if (!connected) return 'Connect to OctoBot to enable controls';
    if (!telemetryFresh) return 'Waiting for fresh ESP32 telemetry';
    if (telemetry.mode != 'manual') return 'Manual mode required';
    if (forwardBlocked) {
      return 'Forward locked · Backward and pivot controls available';
    }
    return 'Hold one direction to move · Release to stop';
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
      _nextPressId = 0;
      _activePressId = null;
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
          // Only an active forward hold is interrupted by front proximity.
          if (hasMotion && (!manualArmed ||
              (forward > 0.10 && forwardBlocked))) stop();
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
    _activePressId = null;
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
    if (!connected || _activePressId == null) return;
    _send({
      'type': 'drive',
      'press_id': _activePressId,
      'forward': double.parse(forward.toStringAsFixed(3)),
      'turn': double.parse(turn.toStringAsFixed(3)),
      'speed': double.parse(speed.toStringAsFixed(2)),
      'gait': gait,
    });
  }

  void _tick(Timer _) {
    if (!connected) return;
    if (hasMotion && (!manualArmed ||
        (forward > 0.10 && forwardBlocked))) {
      stop();
      _log('Motion stopped: connection telemetry stale or manual mode exited');
    } else if (hasMotion) {
      _sendMotion();
    }
    _ticks++;
    if (_ticks % 5 == 0) {
      _send({'type': 'heartbeat'});
      notifyListeners(); // Update stale telemetry/lock indicators.
    }
  }

  /// A new press ID is assigned only when a NEW hold begins.
  /// Old presses can never resume after ESP32 obstacle interruption.
  void setMotion({required double nextForward, required double nextTurn}) {
    if (!manualArmed || hasMotion) return;
    if (nextForward > 0.10 && forwardBlocked) return;
    final f = nextForward.clamp(-1.0, 1.0).toDouble();
    final t = nextTurn.clamp(-1.0, 1.0).toDouble();
    if ((f.abs() > .10 && t.abs() > .10) ||
        (f.abs() <= .10 && t.abs() <= .10)) return;
    forward = f.abs() < .10 ? 0 : f;
    turn = t.abs() < .10 ? 0 : t;
    _activePressId = ++_nextPressId;
    _sendMotion();
    notifyListeners();
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
    _activePressId = null;
    _send({'type': 'stop'});
    notifyListeners();
  }

  void requestMode(String requested) {
    if (!connected || requested != 'manual') return;
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
