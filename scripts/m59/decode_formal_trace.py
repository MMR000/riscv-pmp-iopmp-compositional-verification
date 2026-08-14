#!/usr/bin/env python3
"""Decode SymbiYosys VCD witness for M57 full-RTL harness (M5.9)."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

SIGNALS = [
    "rst_n",
    "formal_reset_phase",
    "src_aw_valid",
    "src_w_valid",
    "slv_aw_valid",
    "slv_aw_ready",
    "slv_w_valid",
    "slv_w_ready",
    "mst_req.w_valid",
    "mst_rsp.w_ready",
    "grant_allow",
    "grant_seq",
    "txn_seq",
    "txn_active",
    "route_select_q",
    "state_q",
    "env_allow",
    "env_grant_valid",
    "ini_aw_ready",
    "ini_w_ready",
]


def parse_vcd(path: Path) -> tuple[list[int], dict[str, list[str]]]:
    text = path.read_text(errors="replace").splitlines()
    id_to_name: dict[str, str] = {}
    width: dict[str, int] = {}
    for ln in text:
        if ln.startswith("$var"):
            parts = ln.split()
            if len(parts) >= 5:
                w, vid, name = parts[2], parts[3], parts[4]
                id_to_name[vid] = name
                width[vid] = int(w)
    times: list[int] = []
    cur: dict[str, str] = {}
    hist: dict[str, list[str]] = {n: [] for n in SIGNALS}

    def snapshot(t: int) -> None:
        if not times or times[-1] != t:
            times.append(t)
            for n in SIGNALS:
                hist[n].append(cur.get(n, "?"))

    for ln in text:
        if ln.startswith("#"):
            snapshot(int(ln[1:]))
            continue
        if not ln:
            continue
        c0 = ln[0]
        if c0 in "01xXzZ":
            if len(ln) > 1 and ln[1] in "01xXzZ":
                val, vid = ln[0], ln[1:]
            else:
                val, vid = c0, ln[1:]
            name = id_to_name.get(vid, "")
            cur[vid] = val
            # map aliases
            for want in SIGNALS:
                if want in name or name.endswith(want.split(".")[-1]):
                    cur[want] = val if width.get(vid, 1) == 1 else ln[1:] if ln[0] in "b" else val
        elif c0 == "b":
            parts = ln.split()
            if len(parts) == 2:
                val, vid = parts[0][1:], parts[1]
                name = id_to_name.get(vid, "")
                cur[vid] = val
                for want in SIGNALS:
                    if want in name or name.endswith(want.split(".")[-1]):
                        cur[want] = val

    if not times:
        snapshot(0)
    return times, hist


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("vcd", type=Path)
    ap.add_argument("-o", "--output", type=Path)
    args = ap.parse_args()
    times, hist = parse_vcd(args.vcd)
    lines = ["cycle,time_ps," + ",".join(SIGNALS)]
    for i, t in enumerate(times):
        row = [str(i), str(t)] + [hist[s][i] if i < len(hist[s]) else "?" for s in SIGNALS]
        lines.append(",".join(row))
    out = "\n".join(lines) + "\n"
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(out)
    else:
        sys.stdout.write(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
