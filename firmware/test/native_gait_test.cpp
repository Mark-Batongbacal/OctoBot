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
  std::cout << "Gait unit checks passed.\n";
}
