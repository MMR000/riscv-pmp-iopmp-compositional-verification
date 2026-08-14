"""Cocotb testbench wrapper for soc_top."""

import os
from pathlib import Path

from cocotb_test.simulator import run

ROOT = Path(__file__).resolve().parents[2]
RTL = ROOT / "rtl"

def test_soc_top():
    run(
        verilog_sources=[
            RTL / "memory/sram.v",
            RTL / "cpu_master/cpu_master.v",
            RTL / "dma/dma_master.v",
            RTL / "pmp/pmp.v",
            RTL / "iopmp/iopmp.v",
            RTL / "interconnect/interconnect.v",
            RTL / "soc/security_config.v",
            RTL / "soc/soc_top.v",
        ],
        includes=[str(RTL / "common")],
        toplevel="soc_top",
        module="test_m1",
        simulator="icarus",
        extra_args=["-g2012"],
        waves=True,
    )
