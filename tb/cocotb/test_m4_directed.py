"""M4B full directed reset matrix R01–R16."""

import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock

from m4_experiment_lib import EXPERIMENTS, M4_CFG, WAVEFORM_SCENARIOS
from soc_test_lib import git_commit, write_csv

MATRIX_PATH = Path(__file__).resolve().parents[2] / "results" / "tables" / "m4_directed_reset_matrix.csv"
WAVE_DIR = Path(__file__).resolve().parents[2] / "results" / "m4" / "waveforms"
ROWS = []


def _maybe_save_wave(dut, exp_id: str):
    if (M4_CFG, exp_id) not in WAVEFORM_SCENARIOS:
        return ""
    WAVE_DIR.mkdir(parents=True, exist_ok=True)
    name = f"m4_{exp_id.lower()}_{M4_CFG.lower()}_security_config_last"
    if exp_id == "R01":
        name = f"m4_r01_{M4_CFG.lower()}_dma_before_iopmp"
    elif exp_id == "R16":
        name = f"m4_r16_{M4_CFG.lower()}_secure_ready_deassert"
    elif exp_id == "R03":
        name = f"m4_r03_{M4_CFG.lower()}_security_config_last"
    elif exp_id == "R09":
        name = f"m4_r09_{M4_CFG.lower()}_reset_during_auth_dma"
    elif exp_id == "R11":
        name = f"m4_r11_{M4_CFG.lower()}_pending_write_reset"
    src = Path(__file__).resolve().parent / "sim_build" / "soc_top.fst"
    if src.exists():
        dst = WAVE_DIR / f"{name}.fst"
        try:
            dst.write_bytes(src.read_bytes())
            return str(dst)
        except OSError:
            pass
    return ""


async def _run_all(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    for eid, fn in EXPERIMENTS.items():
        res = await fn(dut)
        row = res.as_row()
        row["git_commit"] = git_commit()
        row["waveform"] = _maybe_save_wave(dut, eid)
        ROWS.append(row)


@cocotb.test()
async def m4_directed_matrix(dut):
    await _run_all(dut)
    fields = [
        "experiment_id", "scenario", "configuration", "reset_default", "admission_gate",
        "commit_epoch", "initial_state", "reset_sequence", "expected", "observed",
        "property_ids", "result", "classification", "waveform", "notes", "git_commit",
    ]
    per_cfg = Path(__file__).resolve().parents[2] / "results" / "simulation" / f"m4_directed_matrix_{M4_CFG}.csv"
    write_csv(per_cfg, ROWS, fields)
    assert len(ROWS) == len(EXPERIMENTS)
