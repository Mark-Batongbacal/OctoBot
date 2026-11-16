#pragma once
#include <Arduino.h>
#include <ESPAsyncWebServer.h>
#include <atomic>
#include "RobotState.h"

class RobotNetwork {
 public:
  explicit RobotNetwork(RobotState& state);
  bool begin();
  void telemetry(const Snapshot& snapshot);
  void housekeeping();
 private:
  RobotState& state_;
  AsyncWebServer server_{80};
  AsyncWebSocket ws_{"/ws"};
  std::atomic<uint32_t> owner_{0};
  void onEvent(AsyncWebSocket* server, AsyncWebSocketClient* client,
               AwsEventType type, void* arg, uint8_t* data, size_t len);
  void handleJson(uint32_t client, AsyncWebSocketClient* connection,
                  const uint8_t* bytes, size_t len);
  void sendError(AsyncWebSocketClient* client, const char* reason);
};
