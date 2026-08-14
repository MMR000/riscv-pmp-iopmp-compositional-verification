"""Pytest wrapper for isolated M4 waveform capture."""

import os
import shutil
from pathlib import Path

from cocotb_test.simulator import run

ROOT = Path(__file__).resolve().parents[2]
RTL = ROOT / "rtl"
TB = Path(__file__).resolve().parent
WAVE_DIR = ROOT / "results" / "m4" / "waveforms"

CONFIG_DEFINES = {
    "C0": [],
    "C1": ["-DRST_B"],
    "C2": ["-DRSDG_ADMIT_GATE"],
    "C3": ["-DRSDG_ADMIT_GATE", "-DRSDG_COMMIT_EPOCH"],
    "C4": ["-DRST_B", "-DRSDG_ADMIT_GATE"],
}

WAVE_NAMES = {
    "R01": "m4_r01_{cfg}_dma_before_iopmp",
    "R03": "m4_r03_{cfg}_security_config_last",
    "R07": "m4_r07_{cfg}_iopmp_disable_bypass",
    "R09": "m4_r09_{cfg}_reset_during_auth_dma",
    "R11": "m4_r11_{cfg}_pending_write_reset",
    "R16": "m4_r16_{cfg}_secure_ready_deassert",
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
    ]
    if cfg in ("C2", "C3", "C4"):
        srcs.append(RTL / "soc/rsdg.v")
    return srcs


def test_m4_waveform_soc_top():
    cfg = os.environ.get("M4_CONFIG", "C0")
    scenario = os.environ.get("M4_WAVE_SCENARIO", "R01")
    run(
        verilog_sources=_sources(cfg),
        includes=[str(RTL / "common")],
        toplevel="soc_top",
        module="test_m4_waveform",
        simulator="icarus",
        extra_args=["-g2012"] + CONFIG_DEFINES.get(cfg, []),
        waves=True,
    )
    WAVE_DIR.mkdir(parents=True, exist_ok=True)
    src = TB / "sim_build" / "soc_top.fst"
    tpl = WAVE_NAMES.get(scenario, f"m4_{scenario.lower()}_{{cfg}}")
    dst = WAVE_DIR / f"{tpl.format(cfg=cfg.lower())}.fst"
    assert src.exists(), f"Missing simulation waveform {src}"
    assert src.stat().st_size > 1024, f"Undersized waveform {src} ({src.stat().st_size} bytes)"
    shutil.copy2(src, dst)
