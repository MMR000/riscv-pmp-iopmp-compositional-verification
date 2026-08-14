"""Pytest wrapper for M7 reset matrix."""

import os
from pathlib import Path

from cocotb_test.simulator import run

ROOT = Path(__file__).resolve().parents[2]
RTL = ROOT / "rtl"

CONFIG_DEFINES = {
    "C0": [],
    "C1": ["-DRST_B"],
    "C2": ["-DRSDG_ADMIT_GATE"],
    "C4": ["-DRST_B", "-DRSDG_ADMIT_GATE"],
}


def _sources(cfg):
    srcs = [
        RTL / "memory/sram.v",
        RTL / "cpu_master/cpu_master.v",
        RTL / "dma/dma_master.v",
        RTL / "pmp/pmp.v",
        RTL / "iopmp/iopmp.v",
        RTL / "interconnect/interconnect.v",
        RTL / "soc/security_config.v",
        RTL / "soc/soc_top.v",
        RTL / "soc/m7_reset_top.v",
    ]
    if cfg in ("C2", "C4"):
        srcs.append(RTL / "soc/rsdg.v")
    return srcs


def test_m7_reset_matrix():
    cfg = os.environ.get("M7_RESET_CONFIG", "C0")
    run(
        verilog_sources=_sources(cfg),
        includes=[str(RTL / "common")],
        toplevel="m7_reset_top",
        module="test_m7_reset",
        simulator="icarus",
        extra_args=["-g2012"] + CONFIG_DEFINES.get(cfg, []),
    )
