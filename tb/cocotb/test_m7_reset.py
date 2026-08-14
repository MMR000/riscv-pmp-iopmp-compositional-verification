"""Cocotb M7 reset matrix tests."""

import csv
import os
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

from m7_reset_lib import EXPERIMENTS, run_randomized_order
from soc_test_lib import reset_dut

RESULTS: list[dict] = []

OUT = Path(os.environ.get("M7_RESET_OUT", Path(__file__).resolve().parents[2] / "results/m7/reset"))
CFG = os.environ.get("M7_RESET_CONFIG", "C0")
OUT.mkdir(parents=True, exist_ok=True)
RAW = OUT / f"m7_reset_raw_{CFG}.csv"


@cocotb.test()
async def m7_reset_matrix(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    for sig in ("cpu_rst_n", "dma_rst_n", "iopmp_rst_n", "sec_rst_n", "ic_rst_n", "mem_rst_n"):
        getattr(dut, sig).value = 1
    await reset_dut(dut)
    for _name, fn in EXPERIMENTS.items():
        await RisingEdge(dut.clk)
        res = await fn(dut)
        RESULTS.append(res.as_row())
    n = int(os.environ.get("M7_RANDOM_SEEDS", "32"))
    for seed in range(n):
        await RisingEdge(dut.clk)
        res = await run_randomized_order(dut, seed)
        RESULTS.append(res.as_row())

    if RESULTS:
        with RAW.open("w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(RESULTS[0].keys()))
            w.writeheader()
            w.writerows(RESULTS)
