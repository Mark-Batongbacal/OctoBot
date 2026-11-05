#include "RobotNetwork.h"
#include "Config.h"
#include <ArduinoJson.h>
#include <WiFi.h>
#include <cmath>

RobotNetwork::RobotNetwork(RobotState& state) : state_(state) {}
bool RobotNetwork::begin() {
  WiFi.mode(WIFI_AP);
  if (!WiFi.softAP(cfg::kApSsid, cfg::kApPassword)) return false;
  ws_.onEvent([this](AsyncWebSocket* server, AsyncWebSocketClient* client,
                     AwsEventType type, void* arg, uint8_t* data, size_t len) {
    onEvent(server, client, type, arg, data, len);
  });
  server_.on("/health", HTTP_GET, [](AsyncWebServerRequest* request) {
    request->send(200, "application/json", "{\"service\":\"octobot\",\"status\":\"online\"}");
  });
  server_.addHandler(&ws_);
  server_.begin();
  Serial.printf("OctoBot AP: %s / IP: %s / WS: /ws\n", cfg::kApSsid,
                WiFi.softAPIP().toString().c_str());
  return true;
}
void RobotNetwork::sendError(AsyncWebSocketClient* client, const char* reason) {
  if (!client) return;
  JsonDocument doc;
  doc["type"] = "error";
  doc["message"] = reason;
  String out;
  serializeJson(doc, out);
  client->text(out);
}
void RobotNetwork::onEvent(AsyncWebSocket*, AsyncWebSocketClient* client,
                            AwsEventType type, void* arg, uint8_t* data, size_t len) {
  if (!client) return;
  const uint32_t id = client->id();
  if (type == WS_EVT_CONNECT) {
    uint32_t expected = 0;
    if (!owner_.compare_exchange_strong(expected, id)) {
      sendError(client, "OctoBot already has a controller");
      client->close();
      return;
    }
    state_.connected(id, millis());
  } else if (type == WS_EVT_DISCONNECT) {
    uint32_t expected = id;
    if (owner_.compare_exchange_strong(expected, 0)) state_.disconnected(id);
  } else if (type == WS_EVT_DATA && owner_.load() == id) {
    auto* info = static_cast<AwsFrameInfo*>(arg);
    // Ignore non-text, fragmented, or oversized messages. Only a full frame
    // is parsed; never assume an extra terminating NUL exists in 'data'.
    if (!info || info->opcode != WS_TEXT || !info->final || info->index != 0 ||
        info->len != len || len > cfg::kMaxWebSocketPacketBytes) {
      sendError(client, "Invalid or fragmented command");
      return;
    }
    handleJson(id, client, data, len);
  }
}
void RobotNetwork::handleJson(uint32_t id, AsyncWebSocketClient* client,
                               const uint8_t* bytes, size_t len) {
  JsonDocument doc;
  const auto result = deserializeJson(doc, reinterpret_cast<const char*>(bytes), len);
  if (result || !doc.is<JsonObject>()) { sendError(client, "Invalid JSON"); return; }
  const char* type = doc["type"].as<const char*>();
  if (!type) { sendError(client, "Missing command type"); return; }
  if (!strcmp(type, "stop")) {
    state_.stop(id); // immediate command invalidation, no network task motion I/O
  } else if (!strcmp(type, "heartbeat")) {
    state_.heartbeat(id, millis());
  } else if (!strcmp(type, "mode")) {
    const char* mode = doc["value"].as<const char*>();
    if (mode && !strcmp(mode, "manual")) state_.changeMode(id, Mode::Manual);
    else if (mode && !strcmp(mode, "autonomous")) state_.changeMode(id, Mode::Autonomous);
    else sendError(client, "Invalid mode");
  } else if (!strcmp(type, "drive")) {
    const JsonVariantConst forward = doc["forward"];
    const JsonVariantConst turn = doc["turn"];
    const JsonVariantConst speed = doc["speed"];
    const char* gait = doc["gait"].as<const char*>();
    const bool numeric = [](JsonVariantConst v) { return v.is<float>() ||
        v.is<double>() || v.is<int>(); }(forward) &&
        [](JsonVariantConst v) { return v.is<float>() ||
        v.is<double>() || v.is<int>(); }(turn) &&
        [](JsonVariantConst v) { return v.is<float>() ||
        v.is<double>() || v.is<int>(); }(speed);
    if (!numeric || !gait) { sendError(client, "Invalid drive fields"); return; }
    DriveCommand cmd;
    cmd.forward = forward.as<float>();
    cmd.turn = turn.as<float>();
    cmd.speed = speed.as<float>();
    if (!std::isfinite(cmd.forward) || !std::isfinite(cmd.turn) || !std::isfinite(cmd.speed) ||
        fabsf(cmd.forward) > 1 || fabsf(cmd.turn) > 1 ||
        cmd.speed < 0.10f || cmd.speed > 1.0f) {
      sendError(client, "Drive values out of range"); return;
    }
    if (!strcmp(gait, "reciprocal")) cmd.gait = Gait::Reciprocal;
    else if (!strcmp(gait, "wave")) cmd.gait = Gait::Wave;
    else { sendError(client, "Unknown gait"); return; }
    state_.drive(id, cmd, millis());
  } else {
    sendError(client, "Unknown command type");
  }
}
void RobotNetwork::telemetry(const Snapshot& s) {
  const uint32_t id = owner_.load();
  if (id == 0) return;
  AsyncWebSocketClient* client = ws_.client(id);
  if (!client || !client->canSend()) return;
  JsonDocument doc;
  doc["type"] = "telemetry";
  doc["mode"] = modeName(s.mode);
  doc["state"] = activityName(s.activity);
  doc["gait_phase"] = String(s.gaitPhase);
  doc["obstacle"] = s.obstacle;
  if (s.sensorValid && (millis() - s.sensorAtMs < cfg::kSensorStaleMs))
    doc["distance_cm"] = s.distanceCm;
  else doc["distance_cm"] = nullptr;
  if (s.batteryKnown) doc["battery_voltage"] = s.batteryVoltage;
  else doc["battery_voltage"] = nullptr;
  doc["calibrated"] = s.calibrated;
  doc["hardware_armed"] = s.hardwareArmed;
  doc["emergency_latched"] = s.emergencyLatched;
  doc["gait"] = gaitName(s.gait);
  String message;
  serializeJson(doc, message);
  client->text(message);
}
void RobotNetwork::housekeeping() { ws_.cleanupClients(); }
