#include <cassert>
#include <cmath>
#include <iostream>
#include "GaitEngine.h"

int main() {
  // Blue/orange PAIR colors do not define the swing groups!
  assert(GaitEngine::swingGroupA(0)); // L1
  assert(!GaitEngine::swingGroupA(4)); // R1
  assert(!GaitEngine::swingGroupA(1)); // L2
  assert(GaitEngine::swingGroupA(5)); // R2
  assert(GaitEngine::swingGroupA(2)); // L3
  assert(!GaitEngine::swingGroupA(6)); // R3
  assert(!GaitEngine::swingGroupA(3)); // L4
  assert(GaitEngine::swingGroupA(7)); // R4
  for (int step=0;step<200;step++) {
    const float phase=step/200.0f;
    int liftedWave=0, liftedReciprocal=0;
    for (int l=0;l<8;l++) {
      auto wave=GaitEngine::sample(l,Gait::Wave,phase,1,0);
      auto reciprocal=GaitEngine::sample(l,Gait::Reciprocal,phase,1,0);
      assert(wave.horizontal>=-1.001f && wave.horizontal<=1.001f);
      assert(wave.lift>=0 && wave.lift<=1.001f);
      if(wave.lift>0.0001f) liftedWave++;
      if(reciprocal.lift>0.0001f) liftedReciprocal++;
      const auto right=GaitEngine::sample(l,Gait::Reciprocal,phase,0,1);
      if(l<4) assert(right.horizontal==reciprocal.horizontal || std::isfinite(right.horizontal));
    }
    assert(liftedWave<=1);
    assert(liftedReciprocal<=4);
  }
  // For a right-turn command, stance strokes on the two sides oppose.
  const auto l0=GaitEngine::sample(0,Gait::Reciprocal,0.40f,0,1);
  const auto l1=GaitEngine::sample(0,Gait::Reciprocal,0.41f,0,1);
  const auto r0=GaitEngine::sample(4,Gait::Reciprocal,0.40f,0,1);
  const auto r1=GaitEngine::sample(4,Gait::Reciprocal,0.41f,0,1);
  assert((l1.horizontal-l0.horizontal)*(r1.horizontal-r0.horizontal)<0);
  // Symmetric reverse travel: invert horizontal foot strokes, preserve lift.
  for (int leg = 0; leg < 8; ++leg) {
    for (int step = 0; step < 50; ++step) {
      const float cycle = step / 50.0f;
      const auto forward = GaitEngine::sample(leg, Gait::Reciprocal, cycle, .6f, 0);
      const auto reverse = GaitEngine::sample(leg, Gait::Reciprocal, cycle, -.6f, 0);
      assert(std::fabs(forward.horizontal + reverse.horizontal) < 0.0001f);
      assert(std::fabs(forward.lift - reverse.lift) < 0.0001f);
      // In-place rotation: opposite sides always have opposite drive signs.
      const auto cw = GaitEngine::sample(leg, Gait::Reciprocal, cycle, 0, .6f);
      const auto ccw = GaitEngine::sample(leg, Gait::Reciprocal, cycle, 0, -.6f);
      assert(std::fabs(cw.horizontal + ccw.horizontal) < 0.0001f);
      assert(std::fabs(cw.lift - ccw.lift) < 0.0001f);
    }
  }

  // A forward-right diagonal is differential steering: left stride grows,
  // right stride shrinks. It is NOT a true lateral strafe.
  const auto leftStraight = GaitEngine::sample(0, Gait::Reciprocal, .40f, .5f, 0);
  const auto leftCurved = GaitEngine::sample(0, Gait::Reciprocal, .40f, .5f, .25f);
  const auto rightStraight = GaitEngine::sample(4, Gait::Reciprocal, .40f, .5f, 0);
  const auto rightCurved = GaitEngine::sample(4, Gait::Reciprocal, .40f, .5f, .25f);
  assert(std::fabs(leftCurved.horizontal) > std::fabs(leftStraight.horizontal));
  assert(std::fabs(rightCurved.horizontal) < std::fabs(rightStraight.horizontal));

  // Faster selected speed produces a shorter reciprocal/wave cycle.
  assert(GaitEngine::cycleMs(Gait::Reciprocal, .1f) >
         GaitEngine::cycleMs(Gait::Reciprocal, .9f));
  assert(GaitEngine::cycleMs(Gait::Wave, .1f) >
         GaitEngine::cycleMs(Gait::Wave, .9f));
  std::cout << "Gait unit checks passed.\n";
}
