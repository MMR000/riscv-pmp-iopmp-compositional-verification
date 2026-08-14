"""Pytest wrapper for M4 reset/recovery experiments."""

import os
from pathlib import Path

from cocotb_test.simulator import run

ROOT = Path(__file__).resolve().parents[2]
RTL = ROOT / "rtl"

CONFIG_DEFINES = {
    "C0": [],
    "C1": ["-DRST_B"],
    "C2": ["-DRSDG_ADMIT_GATE"],
    "C3": ["-DRSDG_ADMIT_GATE", "-DRSDG_COMMIT_EPOCH"],
    "C4": ["-DRST_B", "-DRSDG_ADMIT_GATE"],
}


def _verilog_sources():
    srcs = [
        RTL / "memory/sram.v",
        RTL / "cpu_master/cpu_master.v",
        RTL / "dma/dma_master.v",
        RTL / "pmp/pmp.v",
        RTL / "iopmp/iopmp.v",
        RTL / "interconnect/interconnect.v",
        RTL / "soc/security_config.v",
        RTL / "soc/soc_top.v",
    ]
    cfg = os.environ.get("M4_CONFIG", "C0")
    if cfg in ("C2", "C3", "C4"):
        srcs.append(RTL / "soc/rsdg.v")
    return srcs


def _compile_args():
    cfg = os.environ.get("M4_CONFIG", "C0")
    return ["-g2012"] + CONFIG_DEFINES.get(cfg, [])


def test_m4_soc_top():
    run(
        verilog_sources=_verilog_sources(),
        includes=[str(RTL / "common")],
        toplevel="soc_top",
        module="test_m4",
        simulator="icarus",
        extra_args=_compile_args(),
        waves=True,
    )
