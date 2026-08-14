#!/usr/bin/env python3
"""Extract ORFS sky130hd metrics for one M7 J-variant into a JSON sidecar."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path("/home/mmr/ricv_paper")
FLOW = ROOT / "third_party/OpenROAD-flow-scripts/flow"


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text())


def synth_cell_breakdown(stat: Path) -> dict:
    out = {
        "synth_cells": "N/A",
        "synth_comb_cells": "N/A",
        "synth_seq_cells": "N/A",
        "synth_area": "N/A",
        "synth_buf_cells": "N/A",
        "synth_inv_cells": "N/A",
    }
    if not stat.exists():
        return out
    text = stat.read_text()
    # Last "Chip area for module" is the top.
    areas = re.findall(r"Chip area for module '\\[^']+':\s+([0-9.]+)", text)
    if areas:
        out["synth_area"] = float(areas[-1])
    # Top-module cell table: first integer on the "cells" summary line after === top ===
    tops = list(re.finditer(r"^=== (\S+) ===", text, re.M))
    if not tops:
        return out
    start = tops[-1].end()
    chunk = text[start:]
    cut = re.search(r"Chip area for module", chunk)
    if cut:
        chunk = chunk[: cut.start()]
    m = re.search(r"^\s+(\d+)\s+[0-9.E+-]+\s+\d+\s+[0-9.E+-]+\s+cells", chunk, re.M)
    if m:
        out["synth_cells"] = int(m.group(1))
    seq = 0
    inv = 0
    buf = 0
    for name, n in re.findall(
        r"^\s+(\d+)\s+[0-9.E+-]+\s+\d+\s+[0-9.E+-]+\s+sky130_fd_sc_hd__(\S+)",
        chunk,
        re.M,
    ):
        cnt = int(name)
        cell = n
        if re.match(r"(df|edf|dlxt)", cell):
            seq += cnt
        if "inv" in cell or cell.startswith("clkinv"):
            inv += cnt
        if cell.startswith("buf") or "clkbuf" in cell:
            buf += cnt
    if out["synth_cells"] != "N/A":
        out["synth_seq_cells"] = seq
        out["synth_comb_cells"] = out["synth_cells"] - seq
        out["synth_inv_cells"] = inv
        out["synth_buf_cells"] = buf
    return out


def extract(variant: str, flow_variant: str = "base") -> dict:
    nick = f"m7_{variant.lower()}"
    logs = FLOW / f"logs/sky130hd/{nick}/{flow_variant}"
    reports = FLOW / f"reports/sky130hd/{nick}/{flow_variant}"
    results = FLOW / f"results/sky130hd/{nick}/{flow_variant}"
    synth = load_json(logs / "1_synth.json")
    place = load_json(logs / "3_5_place_dp.json")
    finish = load_json(logs / "6_report.json")
    cts = load_json(logs / "4_1_cts.json")
    route = load_json(logs / "5_2_route.json")
    grt = load_json(logs / "5_1_grt.json")
    br = synth_cell_breakdown(reports / "synth_stat.txt")
    setup_ws = finish.get("finish__timing__setup__ws", "N/A")
    setup_tns = finish.get("finish__timing__setup__tns", "N/A")
    hold_ws = finish.get("finish__timing__hold__ws", "N/A")
    hold_tns = finish.get("finish__timing__hold__tns", "N/A")
    timing_pass = "N/A"
    if setup_ws != "N/A" and setup_tns != "N/A":
        timing_pass = "PASS" if float(setup_ws) >= 0 and float(setup_tns) == 0 else "FAIL"
    gds = list(results.glob("6_final.gds*")) + list(results.glob("6_1_merged.gds*"))
    drc = route.get("detailedroute__route__drc_errors", "N/A")
    result = "PASS" if timing_pass == "PASS" and gds and drc == 0 else "N/A"
    if not finish and cts:
        result = "NO_POST_ROUTE"
    return {
        "variant": variant,
        **br,
        "synth_instance_count_odb": synth.get("synth__design__instance__count", "N/A"),
        "place_area": place.get("detailedplace__design__instance__area__stdcell", "N/A"),
        "place_core_area": place.get("detailedplace__design__core__area", "N/A"),
        "place_die_area": place.get("detailedplace__design__die__area", "N/A"),
        "place_utilization": place.get("detailedplace__design__instance__utilization", "N/A"),
        "cts_setup_wns_ns": cts.get("cts__timing__setup__ws", "N/A"),
        "cts_setup_tns_ns": cts.get("cts__timing__setup__tns", "N/A"),
        "cts_hold_wns_ns": cts.get("cts__timing__hold__ws", "N/A"),
        "cts_instance_count": cts.get("cts__design__instance__count", "N/A"),
        "route_area": finish.get("finish__design__instance__area__stdcell", "N/A"),
        "core_area": finish.get("finish__design__core__area", place.get("detailedplace__design__core__area", "N/A")),
        "die_area": finish.get("finish__design__die__area", place.get("detailedplace__design__die__area", "N/A")),
        "utilization": finish.get("finish__design__instance__utilization", place.get("detailedplace__design__instance__utilization", "N/A")),
        "setup_wns_ns": setup_ws,
        "setup_tns_ns": setup_tns,
        "hold_wns_ns": hold_ws,
        "hold_tns_ns": hold_tns,
        "timing_pass": timing_pass,
        "route_drc": drc,
        "wirelength": route.get("detailedroute__route__wirelength", "N/A"),
        "buffer_count": finish.get("finish__design__instance__count__class:timing_repair_buffer", "N/A"),
        "inverter_count": finish.get("finish__design__instance__count__class:inverter", "N/A"),
        "gds_generated": "YES" if gds else "NO",
        "gds_path": str(gds[0]) if gds else "N/A",
        "finish_instance_count": finish.get("finish__design__instance__count", "N/A"),
        "grt_status": "FAIL" if not grt and (logs / "5_1_grt.log").exists() else ("DONE" if grt else "N/A"),
        "result": result,
        "logs_dir": str(logs),
        "reports_dir": str(reports),
    }


def main() -> None:
    var = sys.argv[1] if len(sys.argv) > 1 else "J0"
    flow_variant = sys.argv[2] if len(sys.argv) > 2 else "base"
    data = extract(var, flow_variant)
    data["flow_variant"] = flow_variant
    data["clock_period_ns"] = "N/A"
    suffix = "" if flow_variant == "base" else f"_{flow_variant}"
    out = ROOT / f"results/m7/ppa_full/orfs/{var}/metrics{suffix}.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(data, indent=2) + "\n")
    print(json.dumps(data, indent=2))


if __name__ == "__main__":
    main()
