"""Servo channel mapping regression check (not a hardware calibration test)."""
from pathlib import Path
import re

config = (Path(__file__).resolve().parents[1] / "src" / "Config.h").read_text()
mapping = config.split("constexpr LegCalibration kLegCalibration[8] = {", 1)[1].split("};", 1)[0]
pattern = re.compile(r"\{\s*(\d+)\s*,\s*(\d+)\s*,\s*1500\s*,\s*1500\s*,\s*[+-]1\s*,\s*[+-]1\s*\}\s*,?\s*//\s*([LR][1-4])")
found = [[leg, int(hip), int(knee)] for hip, knee, leg in pattern.findall(mapping)]
expected = [["L1",7,6],["L2",3,5],["L3",0,1],["L4",4,2],["R1",13,15],["R2",12,14],["R3",9,8],["R4",10,11]]
assert found == expected, f"Unexpected leg / joint map: {found!r}"
channels = [channel for _, hip, knee in found for channel in (hip, knee)]
assert sorted(channels) == list(range(16)), f"Channels must be exactly CH0..CH15: {channels!r}"
print("Servo channel map passed: eight legs, 16 distinct outputs.")
