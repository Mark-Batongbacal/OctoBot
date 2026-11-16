#pragma once
#include "Types.h"

struct FootTarget {
  float horizontal = 0.0f; // normalized foot displacement (not servo degrees)
  float lift = 0.0f;       // normalized positive foot clearance
};

class GaitEngine {
 public:
  // Index order: L1 L2 L3 L4 R1 R2 R3 R4.
  static bool swingGroupA(unsigned leg);
  static FootTarget sample(unsigned leg, Gait gait, float cycle,
                           float forward, float turn);
  static float cycleMs(Gait gait, float speed);
};
