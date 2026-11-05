#include "GaitEngine.h"
#include <cmath>

namespace {
constexpr float kPi = 3.14159265358979323846f;
float clamp1(float n) { return fmaxf(-1.0f, fminf(1.0f, n)); }
float wrap(float p) { p = p - floorf(p); return p < 0 ? p + 1 : p; }
float smooth(float t) { return 0.5f - 0.5f * cosf(kPi * t); }
// Wave order preserves reciprocal sequence but lifts ONE foot at a time.
// slot 0..7: L1,R2,L3,R4,R1,L2,R3,L4
constexpr int kWaveSlots[8] = {0, 5, 1, 7, 4, 2, 6, 3};
}

bool GaitEngine::swingGroupA(unsigned leg) {
  // A = L1,R2,L3,R4; B = R1,L2,R3,L4.
  return leg == 0 || leg == 2 || leg == 5 || leg == 7;
}
FootTarget GaitEngine::sample(unsigned leg, Gait gait, float cycle,
                              float forward, float turn) {
  if (leg >= 8) return {};
  // Positive turn = right, so left-side forward stroke increases.
  const float leftDrive = clamp1(forward + turn);
  const float rightDrive = clamp1(forward - turn);
  const float localDrive = leg < 4 ? leftDrive : rightDrive;
  const float swingRatio = gait == Gait::Reciprocal ? 0.35f : 0.10f;
  const float phase = gait == Gait::Reciprocal
      ? wrap(cycle + (swingGroupA(leg) ? 0.0f : 0.5f))
      : wrap(cycle + 1.0f - kWaveSlots[leg] / 8.0f);
  FootTarget target;
  if (phase < swingRatio) {
    const float t = phase / swingRatio;
    target.horizontal = (-1.0f + 2.0f * smooth(t)) * localDrive;
    target.lift = sinf(kPi * t);
  } else {
    const float t = (phase - swingRatio) / (1.0f - swingRatio);
    target.horizontal = (1.0f - 2.0f * t) * localDrive;
    target.lift = 0;
  }
  return target;
}
float GaitEngine::cycleMs(Gait gait, float speed) {
  speed = fmaxf(0.10f, fminf(1.0f, speed));
  const float t = (speed - 0.10f) / 0.90f;
  return gait == Gait::Reciprocal ? 2600.0f - 1400.0f * t
                                  : 6400.0f - 2600.0f * t;
}
