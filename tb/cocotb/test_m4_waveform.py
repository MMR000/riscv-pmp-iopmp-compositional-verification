"""M4 isolated waveform capture — one experiment per simulation."""

import os

import cocotb
from cocotb.clock import Clock

from m4_experiment_lib import EXPERIMENTS

SCENARIO = os.environ.get("M4_WAVE_SCENARIO", "R01")


@cocotb.test()
async def m4_waveform_capture(dut):
    fn = EXPERIMENTS.get(SCENARIO)
    if fn is None:
        raise RuntimeError(f"Unknown scenario {SCENARIO}")
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await fn(dut)
