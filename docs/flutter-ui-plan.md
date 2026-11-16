# OctoBot Flutter and Arduino IDE controller — implementation summary

The Android Flutter app in `flutter/` communicates with the ESP32 sketch
[`OctoBot.ino`](../OctoBot.ino) over the ESP32's private Wi-Fi and WebSocket
`ws://192.168.4.1/ws`. All active ESP32 code is in `src/`.

**Current user-facing screens:** Drive, Autonomy, Monitor and Connect.
Drive includes a 2-axis joystick, press-and-hold eight-direction pad,
reciprocal/wave gait selection, walking-speed slider, and software STOP.
The controller sends the same JSON drive protocol for joystick and buttons.

**Safety conditions:** Control is disabled if real robot telemetry is stale,
un-calibrated, physically disarmed, in E-stop, in fault, or otherwise denied
by the firmware. Forward travel is blocked on a front obstacle; reverse and
stationary turns remain permitted when the front sensor is valid and all
other hardware checks pass. Releasing/cancelling a press commands STOP.
ESP32 watchdogs independently expire stale commands and Wi-Fi control.

**Physical grouping:** A = L1,R2,L3,R4; B = R1,L2,R3,L4.
Forward/reverse and turns use the servo gait engine; diagonals combine
forward+turn into a curved path, **not** straight sideways translation.
Experimental sideways `bop-bop` is not implemented.

**Outstanding hardware tests:** mechanical servo calibration, servo power
rails, E-stop cutoff, sensor readings, gait support/traction, stop latency,
and phone-to-robot movement tests on a securely supported chassis.

For install/build instructions, see the [root README](../README.md) and
the [direction map](directional-control.md).
