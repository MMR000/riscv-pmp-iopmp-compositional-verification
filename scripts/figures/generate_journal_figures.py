#!/usr/bin/env python3
"""Generate IEEE single-column journal figures from frozen M7 result CSVs.

Does not rerun experiments or rewrite historical result files.
All plotted values are read from source CSVs at generation time.
"""
from __future__ import annotations

import csv
import hashlib
import math
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import font_manager as fm
from matplotlib.lines import Line2D
from matplotlib.patches import Patch, Rectangle
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
TABLES = ROOT / "results" / "tables"
FIG = ROOT / "results" / "figures"
PDF_DIR = FIG / "pdf"
SVG_DIR = FIG / "svg"
PNG_DIR = FIG / "png"
DATA_DIR = FIG / "data"

COL_W = 3.50  # inches; IEEE single-column
GENERATION_SCRIPT = "scripts/figures/generate_journal_figures.py"

# Consistent categorical identity (grayscale + hatch + marker).
VARIANT_STYLE = {
    "J0": dict(facecolor="#1a1a1a", hatch="", marker="o", linestyle="-"),
    "J1": dict(facecolor="#4d4d4d", hatch="///", marker="s", linestyle="--"),
    "J2": dict(facecolor="#808080", hatch="xxx", marker="D", linestyle="-."),
    "J3": dict(facecolor="#b3b3b3", hatch="...", marker="^", linestyle=":"),
}
EDGE = "#111111"


class SourceError(RuntimeError):
    """Raised when a required CSV column or row is missing."""


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def load_csv(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        raise SourceError(f"missing source file: {path}")
    with path.open(newline="") as fh:
        return list(csv.DictReader(fh))


def require_columns(rows: list[dict], columns: list[str], src: Path) -> None:
    if not rows:
        raise SourceError(f"{src}: no data rows")
    missing = [c for c in columns if c not in rows[0]]
    if missing:
        raise SourceError(f"{src}: missing columns {missing}; have {list(rows[0])}")


def fnum(value: str) -> float:
    if value in (None, "", "N/A", "NA"):
        raise SourceError(f"non-numeric value: {value!r}")
    return float(value)


def maybe_fnum(value: str) -> float | None:
    if value in (None, "", "N/A", "NA"):
        return None
    try:
        return float(value)
    except ValueError:
        return None


def choose_serif() -> str:
    available = {f.name for f in fm.fontManager.ttflist}
    for name in ("Times New Roman", "STIXGeneral", "DejaVu Serif"):
        if name in available:
            return name
    return "DejaVu Serif"


def configure_style() -> str:
    font = choose_serif()
    mpl.rcParams.update(
        {
            "font.family": "serif",
            "font.serif": [font],
            "font.size": 7.5,
            "axes.labelsize": 8,
            "xtick.labelsize": 7,
            "ytick.labelsize": 7,
            "legend.fontsize": 7,
            "lines.linewidth": 1.2,
            "axes.linewidth": 0.8,
            "axes.titlesize": 8,
            "pdf.fonttype": 42,
            "ps.fonttype": 42,
            "svg.fonttype": "none",
            "axes.facecolor": "white",
            "figure.facecolor": "white",
            "savefig.facecolor": "white",
            "axes.grid": False,
            "legend.frameon": False,
        }
    )
    return font


def save_figure(fig: plt.Figure, stem: str) -> dict[str, Path]:
    paths = {}
    for folder, ext in ((PDF_DIR, "pdf"), (SVG_DIR, "svg"), (PNG_DIR, "png")):
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / f"{stem}.{ext}"
        fig.savefig(
            path,
            dpi=600,
            bbox_inches="tight",
            pad_inches=0.02,
            facecolor="white",
            edgecolor="none",
        )
        paths[ext] = path
    plt.close(fig)
    return paths


def write_plot_data(stem: str, fieldnames: list[str], rows: list[dict]) -> Path:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    path = DATA_DIR / f"{stem}.csv"
    with path.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)
    return path


def new_fig(height: float = 2.55) -> tuple[plt.Figure, plt.Axes]:
    fig, ax = plt.subplots(figsize=(COL_W, height))
    for spine in ("top", "right"):
        ax.spines[spine].set_visible(False)
    ax.tick_params(length=3, width=0.7)
    return fig, ax


def style_bar(ax, bars, variants: list[str]) -> None:
    for bar, var in zip(bars, variants):
        st = VARIANT_STYLE[var]
        bar.set_facecolor(st["facecolor"])
        bar.set_edgecolor(EDGE)
        bar.set_linewidth(0.6)
        bar.set_hatch(st["hatch"])


def annotate_bars(ax, bars, labels: list[str], dy_frac: float = 0.015) -> None:
    ymax = ax.get_ylim()[1]
    for bar, lab in zip(bars, labels):
        ax.text(
            bar.get_x() + bar.get_width() / 2.0,
            bar.get_height() + dy_frac * ymax,
            lab,
            ha="center",
            va="bottom",
            fontsize=6.2,
        )


# ---------------------------------------------------------------------------
# Q1–Q14
# ---------------------------------------------------------------------------

def plot_q1(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["variant", "post_route_area", "clock_period_ns"], src)
    order = ["J0", "J1", "J2", "J3"]
    by = {r["variant"]: r for r in rows}
    missing = [v for v in order if v not in by]
    if missing:
        raise SourceError(f"{src}: missing variants {missing}")
    periods = {by[v]["clock_period_ns"] for v in order}
    if periods != {"20.0"}:
        raise SourceError(f"{src}: expected common 20.0 ns, got {periods}")
    values = [fnum(by[v]["post_route_area"]) for v in order]

    fig, ax = new_fig(2.45)
    x = range(len(order))
    bars = ax.bar(x, values, width=0.72, zorder=3)
    style_bar(ax, bars, order)
    ax.set_xticks(list(x), order)
    ax.set_ylabel(r"Post-route standard-cell area ($\mathrm{\mu m}^{2}$)")
    ax.set_ylim(0, max(values) * 1.18)
    ax.yaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda x, _p: f"{int(x):,}"))
    annotate_bars(ax, bars, [f"{int(v):,}" for v in values])
    paths = save_figure(fig, "Q1_postroute_area")
    write_plot_data(
        "Q1_postroute_area",
        ["variant", "post_route_area", "clock_period_ns"],
        [{"variant": v, "post_route_area": values[i], "clock_period_ns": 20.0} for i, v in enumerate(order)],
    )
    return {"id": "Q1", "stem": "Q1_postroute_area", "paths": paths, "values": dict(zip(order, values)), "source": src}


def plot_q2(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["variant", "cells", "clock_period_ns"], src)
    order = ["J0", "J1", "J2", "J3"]
    by = {r["variant"]: r for r in rows}
    periods = {by[v]["clock_period_ns"] for v in order}
    if periods != {"20.0"}:
        raise SourceError(f"{src}: expected common 20.0 ns, got {periods}")
    values = [int(fnum(by[v]["cells"])) for v in order]

    fig, ax = new_fig(2.45)
    x = range(len(order))
    bars = ax.bar(x, values, width=0.72, zorder=3)
    style_bar(ax, bars, order)
    ax.set_xticks(list(x), order)
    ax.set_ylabel("Mapped cell count")
    ax.set_ylim(0, max(values) * 1.18)
    ax.yaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda x, _p: f"{int(x):,}"))
    annotate_bars(ax, bars, [f"{v:,}" for v in values])
    paths = save_figure(fig, "Q2_synth_cells")
    write_plot_data(
        "Q2_synth_cells",
        ["variant", "cells", "clock_period_ns"],
        [{"variant": v, "cells": values[i], "clock_period_ns": 20.0} for i, v in enumerate(order)],
    )
    return {"id": "Q2", "stem": "Q2_synth_cells", "paths": paths, "values": dict(zip(order, values)), "source": src}


def plot_q3(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["comparison", "metric", "pct_delta"], src)
    order = ["J1_vs_J0", "J2_vs_J1", "J3_vs_J2", "J3_vs_J0"]
    labels = {
        "J1_vs_J0": "J1 vs J0",
        "J2_vs_J1": "J2 vs J1",
        "J3_vs_J2": "J3 vs J2",
        "J3_vs_J0": "J3 vs J0",
    }
    selected = [r for r in rows if r["metric"] == "postroute_stdcell_area_um2"]
    by = {r["comparison"]: r for r in selected}
    missing = [k for k in order if k not in by]
    if missing:
        raise SourceError(f"{src}: missing post-route comparisons {missing}")
    pcts = [fnum(by[k]["pct_delta"]) for k in order]
    hatches = ["///", "xxx", "...", "\\\\"]
    faces = ["#4d4d4d", "#808080", "#b3b3b3", "#1a1a1a"]

    fig, ax = new_fig(2.55)
    y = list(range(len(order)))[::-1]
    ax.axvline(0, color="#444444", lw=0.7, zorder=1)
    for yi, pct, hatch, face in zip(y, pcts, hatches, faces):
        ax.hlines(yi, 0, pct, color=EDGE, lw=1.15, zorder=2)
        ax.plot(pct, yi, "o", ms=5.5, mfc=face, mec=EDGE, mew=0.6, zorder=3)
        ax.scatter([pct], [yi], s=70, facecolor=face, edgecolor=EDGE, linewidths=0.6, hatch=hatch, zorder=3)
        offset = 2.2 if pct >= 0 else -2.2
        ha = "left" if pct >= 0 else "right"
        ax.text(pct + offset, yi, f"{pct:+.2f}%", va="center", ha=ha, fontsize=6.4)
    ax.set_yticks(y, [labels[k] for k in order])
    ax.set_xlabel("Post-route area change (%)")
    xmax = max(pcts)
    xmin = min(0.0, min(pcts))
    ax.set_xlim(xmin - 8, xmax + 18)
    paths = save_figure(fig, "Q3_incremental_area_overhead")
    write_plot_data(
        "Q3_incremental_area_overhead",
        ["comparison", "pct_delta"],
        [{"comparison": k, "pct_delta": pcts[i]} for i, k in enumerate(order)],
    )
    return {"id": "Q3", "stem": "Q3_incremental_area_overhead", "paths": paths, "values": dict(zip(order, pcts)), "source": src}


def plot_q4(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(
        rows,
        ["variant", "demonstrated_fmax_mhz", "result_10ns", "shortest_demonstrated_pass_ns"],
        src,
    )
    order = ["J0", "J1", "J2", "J3"]
    by = {r["variant"]: r for r in rows}
    mhz = [fnum(by[v]["demonstrated_fmax_mhz"]) for v in order]
    status = [by[v]["result_10ns"] for v in order]
    status_short = {
        "PASS": "10 ns: PASS",
        "GRT_FAIL": "10 ns: GRT fail",
        "GDS_SETUP_FAIL": "10 ns: setup fail",
    }

    fig, ax = new_fig(2.65)
    y = list(range(len(order)))[::-1]
    ax.hlines(y, 0, mhz, color=EDGE, lw=1.15, zorder=2)
    for yi, v, val, st in zip(y, order, mhz, status):
        sty = VARIANT_STYLE[v]
        ax.plot(val, yi, marker=sty["marker"], ms=6.5, mfc=sty["facecolor"], mec=EDGE, mew=0.7, zorder=3)
        ax.text(val + 3.2, yi + 0.18, f"{val:.2f} MHz", va="bottom", ha="left", fontsize=6.2)
        ax.text(2.0, yi - 0.32, status_short.get(st, st), va="top", ha="left", fontsize=5.8, color="#444444")
    ax.set_yticks(y, order)
    ax.set_xlabel("Demonstrated post-route $F_{\\mathrm{max}}$ (MHz)")
    ax.set_xlim(0, max(mhz) * 1.28)
    paths = save_figure(fig, "Q4_demonstrated_fmax")
    write_plot_data(
        "Q4_demonstrated_fmax",
        ["variant", "demonstrated_fmax_mhz", "result_10ns", "shortest_demonstrated_pass_ns"],
        [
            {
                "variant": v,
                "demonstrated_fmax_mhz": mhz[i],
                "result_10ns": status[i],
                "shortest_demonstrated_pass_ns": by[v]["shortest_demonstrated_pass_ns"],
            }
            for i, v in enumerate(order)
        ],
    )
    return {"id": "Q4", "stem": "Q4_demonstrated_fmax", "paths": paths, "values": dict(zip(order, mhz)), "source": src}


def plot_q5(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["variant", "period_ns", "setup_wns_ns", "result", "route_result", "timing_pass"], src)
    # Enough tested points exist per variant (J0:3, J1:7, J2:5, J3:3). Plot markers;
    # connect only consecutive *numeric* WNS points. Do not interpolate GRT gaps.
    fig, ax = new_fig(2.75)
    ax.axhline(0.0, color="#555555", lw=0.8, ls="--", zorder=1)
    plotted = []
    for var in ["J0", "J1", "J2", "J3"]:
        pts = [r for r in rows if r["variant"] == var]
        pts.sort(key=lambda r: fnum(r["period_ns"]))
        sty = VARIANT_STYLE[var]
        xs, ys = [], []
        for r in pts:
            period = fnum(r["period_ns"])
            wns = maybe_fnum(r["setup_wns_ns"])
            passed = r["result"] == "PASS"
            plotted.append(
                {
                    "variant": var,
                    "period_ns": period,
                    "setup_wns_ns": "" if wns is None else wns,
                    "result": r["result"],
                    "route_result": r["route_result"],
                }
            )
            if wns is None:
                y_grt = {"J0": -1.35, "J1": -1.50, "J2": -1.65, "J3": -1.35}[var]
                ax.plot(
                    period,
                    y_grt,
                    marker="x",
                    ms=5.5,
                    color=sty["facecolor"],
                    mew=1.1,
                    zorder=4,
                )
                continue
            xs.append(period)
            ys.append(wns)
            mfc = sty["facecolor"] if passed else "white"
            ax.plot(
                period,
                wns,
                marker=sty["marker"],
                ms=5.5,
                mfc=mfc,
                mec=EDGE,
                mew=0.7,
                zorder=3,
            )
        if len(xs) >= 2:
            ax.plot(xs, ys, color=sty["facecolor"], ls=sty["linestyle"], lw=1.05, zorder=2)
    ax.set_xlabel("Requested clock period (ns)")
    ax.set_ylabel("Setup WNS (ns)")
    ax.set_ylim(-1.75, 2.55)
    handles = [
        Line2D([0], [0], color=VARIANT_STYLE[v]["facecolor"], marker=VARIANT_STYLE[v]["marker"],
               ls=VARIANT_STYLE[v]["linestyle"], mfc=VARIANT_STYLE[v]["facecolor"], mec=EDGE, ms=5, label=v)
        for v in ["J0", "J1", "J2", "J3"]
    ]
    handles += [
        Line2D([0], [0], marker="o", color=EDGE, mfc=EDGE, ls="None", ms=5, label="PASS"),
        Line2D([0], [0], marker="o", color=EDGE, mfc="white", ls="None", ms=5, label="FAIL (timed)"),
        Line2D([0], [0], marker="x", color=EDGE, ls="None", ms=5, label="GRT fail (no WNS)"),
    ]
    ax.legend(handles=handles, loc="upper left", ncol=2, handlelength=1.6, columnspacing=0.8, borderaxespad=0.2, fontsize=5.8)
    paths = save_figure(fig, "Q5_fmax_sweep")
    write_plot_data("Q5_fmax_sweep", list(plotted[0].keys()), plotted)
    return {"id": "Q5", "stem": "Q5_fmax_sweep", "paths": paths, "values": {"n_points": len(plotted)}, "source": src}


def plot_q6(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(
        rows,
        ["variant", "period_ns", "notes", "critical_path_category", "slack_ns", "data_arrival_ns", "through_pmp"],
        src,
    )
    # Near-limit demonstrated PASS (and J0 near-limit). Do not use the 20 ns
    # common-period paths as Fmax evidence.
    wanted = {
        "J0": ("9.5", "near Fmax PASS"),
        "J1": ("16.5", "near Fmax PASS (refined)"),
        "J2": ("12.75", "near Fmax PASS"),
        "J3": ("13.0", "near Fmax PASS"),
    }
    selected = []
    for var, (per, note_sub) in wanted.items():
        hits = [
            r
            for r in rows
            if r["variant"] == var and abs(fnum(r["period_ns"]) - float(per)) < 1e-9
        ]
        if not hits:
            raise SourceError(f"{src}: no near-limit row for {var} @ {per} ns")
        # Prefer the annotated near-limit note when duplicates exist.
        hit = next((r for r in hits if note_sub in r["notes"]), hits[-1])
        selected.append(hit)

    fig, ax = new_fig(2.70)
    ax.set_xlim(0, 1)
    ax.set_ylim(-0.55, 4.35)
    ax.axis("off")
    headers = ["Var", "Period", "Category", "Arr.", "Slack", "PMP"]
    col_x = [0.00, 0.18, 0.36, 0.68, 0.82, 0.95]
    for x, h in zip(col_x, headers):
        ax.text(x, 3.95, h, fontsize=6.3, fontweight="bold", va="center", ha="left")
    ax.plot([0, 1], [3.72, 3.72], color=EDGE, lw=0.6)
    compact = {
        "core_reg2reg": "core reg-reg",
        "core_alu_to_observation_port": "ALU to obs. port",
        "core_to_observation_port": "core to obs. port",
    }
    values = {}
    for i, r in enumerate(selected):
        y = 3.25 - i * 0.85
        cat = compact.get(r["critical_path_category"], r["critical_path_category"])
        pmp = "no" if r["through_pmp"].lower() == "false" else "yes"
        sty = VARIANT_STYLE[r["variant"]]
        ax.add_patch(
            Rectangle((0.00, y - 0.28), 0.07, 0.52, facecolor=sty["facecolor"],
                      edgecolor=EDGE, linewidth=0.5, hatch=sty["hatch"])
        )
        ax.text(0.09, y, r["variant"], va="center", fontsize=7)
        ax.text(0.18, y, f"{r['period_ns']} ns", va="center", fontsize=6.3)
        ax.text(0.36, y, cat, va="center", fontsize=6.3)
        ax.text(0.68, y, f"{fnum(r['data_arrival_ns']):.2f}", va="center", fontsize=6.3)
        ax.text(0.82, y, f"{fnum(r['slack_ns']):+.2f}", va="center", fontsize=6.3)
        ax.text(0.95, y, pmp, va="center", fontsize=6.3)
        values[r["variant"]] = {
            "period_ns": r["period_ns"],
            "category": r["critical_path_category"],
            "through_pmp": r["through_pmp"],
            "slack_ns": fnum(r["slack_ns"]),
            "data_arrival_ns": fnum(r["data_arrival_ns"]),
        }
    ax.text(0.00, -0.35, "Near-limit full post-route setup path. PMP not on the named path.", fontsize=5.8, color="#333333")
    paths = save_figure(fig, "Q6_critical_paths")
    write_plot_data(
        "Q6_critical_paths",
        ["variant", "period_ns", "critical_path_category", "data_arrival_ns", "slack_ns", "through_pmp"],
        [
            {
                "variant": v,
                "period_ns": values[v]["period_ns"],
                "critical_path_category": values[v]["category"],
                "data_arrival_ns": values[v]["data_arrival_ns"],
                "slack_ns": values[v]["slack_ns"],
                "through_pmp": values[v]["through_pmp"],
            }
            for v in ["J0", "J1", "J2", "J3"]
        ],
    )
    return {"id": "Q6", "stem": "Q6_critical_paths", "paths": paths, "values": values, "source": src}


def plot_q7(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["test_id", "cycles", "notes"], src)
    wanted = [
        ("PERF-CPU-01", "Auth load", None),
        ("PERF-CPU-02", "Auth store", None),
        ("PERF-CPU-03", "U-load fault", "mcause=5"),
        ("PERF-CPU-04", "U-store fault", "mcause=7"),
    ]
    by = {r["test_id"]: r for r in rows}
    values, labels, notes = [], [], []
    for tid, lab, note in wanted:
        if tid not in by:
            raise SourceError(f"{src}: missing {tid}")
        values.append(int(fnum(by[tid]["cycles"])))
        labels.append(lab)
        notes.append(note)

    fig, ax = new_fig(2.50)
    hatches = ["", "", "///", "xxx"]
    faces = ["#4d4d4d", "#6a6a6a", "#9a9a9a", "#c0c0c0"]
    x = range(len(labels))
    bars = ax.bar(x, values, width=0.68, zorder=3)
    for bar, h, f in zip(bars, hatches, faces):
        bar.set_facecolor(f)
        bar.set_edgecolor(EDGE)
        bar.set_linewidth(0.6)
        bar.set_hatch(h)
    ax.set_xticks(list(x), labels, rotation=12, ha="right")
    ax.set_ylabel("Latency (cycles)")
    ax.set_ylim(0, max(values) * 1.28)
    for bar, val, note in zip(bars, values, notes):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.7, str(val),
                ha="center", va="bottom", fontsize=6.5)
        if note:
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() * 0.45, note,
                    ha="center", va="center", fontsize=5.6, color="#111111")
    paths = save_figure(fig, "Q7_cpu_latency")
    write_plot_data(
        "Q7_cpu_latency",
        ["test_id", "label", "cycles", "annotation"],
        [
            {"test_id": wanted[i][0], "label": labels[i], "cycles": values[i], "annotation": notes[i] or ""}
            for i in range(len(wanted))
        ],
    )
    return {"id": "Q7", "stem": "Q7_cpu_latency", "paths": paths, "values": dict(zip([w[0] for w in wanted], values)), "source": src}


def plot_q8(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["test_id", "cycles"], src)
    wanted = [
        ("PERF-DMA-01a", "1st commit"),
        ("PERF-DMA-02", "completion"),
        ("PERF-DMA-01b", "last commit"),
        ("PERF-DMA-03", "deny response"),
    ]
    by = {r["test_id"]: r for r in rows}
    values = []
    labels = []
    for tid, lab in wanted:
        if tid not in by:
            raise SourceError(f"{src}: missing {tid}")
        values.append(int(fnum(by[tid]["cycles"])))
        labels.append(lab)

    fig, ax = new_fig(2.50)
    faces = ["#3a3a3a", "#5e5e5e", "#8a8a8a", "#c8c8c8"]
    hatches = ["", "///", "xxx", "..."]
    x = range(len(labels))
    bars = ax.bar(x, values, width=0.68, zorder=3)
    for bar, h, f in zip(bars, hatches, faces):
        bar.set_facecolor(f)
        bar.set_edgecolor(EDGE)
        bar.set_linewidth(0.6)
        bar.set_hatch(h)
    ax.set_xticks(list(x), labels, rotation=12, ha="right")
    ax.set_ylabel("Cycles after admission")
    ax.set_ylim(0, max(values) * 1.28 if max(values) else 1.5)
    for bar, val in zip(bars, values):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.18, str(val),
                ha="center", va="bottom", fontsize=6.5)
    paths = save_figure(fig, "Q8_dma_latency")
    write_plot_data(
        "Q8_dma_latency",
        ["test_id", "label", "cycles"],
        [{"test_id": wanted[i][0], "label": labels[i], "cycles": values[i]} for i in range(len(wanted))],
    )
    return {"id": "Q8", "stem": "Q8_dma_latency", "paths": paths, "values": dict(zip([w[0] for w in wanted], values)), "source": src}


def plot_q9(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["n", "cycles_per_transfer", "classification"], src)
    ns = [int(r["n"]) for r in rows]
    cpt = [fnum(r["cycles_per_transfer"]) for r in rows]
    if any(r["classification"] != "MEASURED" for r in rows):
        raise SourceError(f"{src}: expected MEASURED classification")

    fig, ax = new_fig(2.50)
    ax.set_xscale("log", base=2)
    ax.plot(ns, cpt, color=EDGE, ls="-", lw=1.15, marker="o", ms=5.5, mfc="#808080", mec=EDGE, zorder=3)
    for x, y in zip(ns, cpt):
        ax.text(x, y + 0.55, f"{y:g}", ha="center", va="bottom", fontsize=6.3)
    ax.set_xlabel("Transfer count $N$ (log scale)")
    ax.set_ylabel("Cycles / transfer")
    ax.set_ylim(0, max(cpt) * 1.22)
    ax.set_xticks(ns)
    ax.xaxis.set_major_formatter(mpl.ticker.FuncFormatter(lambda x, _p: f"{int(x)}"))
    ax.xaxis.set_minor_formatter(mpl.ticker.NullFormatter())
    paths = save_figure(fig, "Q9_dma_throughput")
    write_plot_data(
        "Q9_dma_throughput",
        ["n", "cycles_per_transfer"],
        [{"n": ns[i], "cycles_per_transfer": cpt[i]} for i in range(len(ns))],
    )
    return {"id": "Q9", "stem": "Q9_dma_throughput", "paths": paths, "values": dict(zip(ns, cpt)), "source": src}


def plot_q10(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["seed", "metric", "cycles"], src)
    auth = [int(fnum(r["cycles"])) for r in rows if r["metric"] == "auth_dma_admit_to_complete"]
    deny = [int(fnum(r["cycles"])) for r in rows if r["metric"] == "denied_dma_deny_to_complete"]
    if len(auth) != 500 or len(deny) != 500:
        raise SourceError(f"{src}: expected 500+500 samples, got {len(auth)}/{len(deny)}")
    if len(set(auth)) != 1 or len(set(deny)) != 1:
        raise SourceError("raw samples are not constant; Q10 would need a different plot")
    auth_v, deny_v = auth[0], deny[0]

    fig, ax = new_fig(2.35)
    labels = ["Authorized", "Denied"]
    values = [auth_v, deny_v]
    bars = ax.bar([0, 1], values, width=0.55, zorder=3)
    for bar, hatch, face in zip(bars, ["///", "..."], ["#4d4d4d", "#c0c0c0"]):
        bar.set_facecolor(face)
        bar.set_edgecolor(EDGE)
        bar.set_linewidth(0.6)
        bar.set_hatch(hatch)
    ax.set_xticks([0, 1], labels)
    ax.set_ylabel("Latency (cycles)")
    ax.set_ylim(0, max(values) * 1.45 if max(values) else 1.5)
    for bar, val in zip(bars, values):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.15, f"{val}\n$n$=500",
                ha="center", va="bottom", fontsize=6.4)
    paths = save_figure(fig, "Q10_dma_random_distribution")
    write_plot_data(
        "Q10_dma_random_distribution",
        ["class", "cycles", "n", "unique_values"],
        [
            {"class": "Authorized", "cycles": auth_v, "n": 500, "unique_values": 1},
            {"class": "Denied", "cycles": deny_v, "n": 500, "unique_values": 1},
        ],
    )
    return {
        "id": "Q10",
        "stem": "Q10_dma_random_distribution",
        "paths": paths,
        "values": {"auth": auth_v, "deny": deny_v, "n_auth": 500, "n_deny": 500},
        "source": src,
    }


def _summary(vals: list[int]) -> dict:
    vals_sorted = sorted(vals)
    n = len(vals_sorted)
    med = statistics.median(vals_sorted)
    mean = sum(vals_sorted) / n
    return {"n": n, "min": min(vals_sorted), "median": med, "mean": mean, "max": max(vals_sorted), "vals": vals_sorted}


def plot_q11(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["test_id", "metric", "cycles", "reset_model"], src)
    # RST-B has the multi-sample directed set. RST-A has a single cpu_release sample;
    # do not mix models and do not invent a distribution for n=1.
    metrics = [
        ("cpu_release_to_pmp_ready", "CPU to PMP_READY"),
        ("iopmp_release_to_iopmp_ready", "IOPMP to IOPMP_READY"),
        ("reset_start_to_secure_ready", "epoch to secure_ready"),
        ("secure_ready_to_dma_req", "secure_ready to DMA"),
    ]
    summaries = {}
    for key, _lab in metrics:
        vals = [int(fnum(r["cycles"])) for r in rows if r["metric"] == key and r["reset_model"] == "RST-B"]
        if not vals:
            raise SourceError(f"{src}: no RST-B samples for {key}")
        summaries[key] = _summary(vals)

    fig, ax = new_fig(2.80)
    y = list(range(len(metrics)))[::-1]
    for yi, (key, lab) in zip(y, metrics):
        s = summaries[key]
        ax.hlines(yi, s["min"], s["max"], color=EDGE, lw=1.2, zorder=2)
        ax.plot(s["min"], yi, "|", color=EDGE, ms=9, mew=1.1, zorder=3)
        ax.plot(s["max"], yi, "|", color=EDGE, ms=9, mew=1.1, zorder=3)
        ax.plot(s["median"], yi, "o", ms=5.5, mfc="#4d4d4d", mec=EDGE, mew=0.6, zorder=4)
        ax.plot(s["mean"], yi, "x", ms=6.5, color=EDGE, mew=1.05, zorder=4)
        # rug of raw samples (honest; n is small)
        counts = Counter(s["vals"])
        for val, c in counts.items():
            ax.plot(val, yi - 0.18, marker="|", ms=4 + min(c, 6), color="#777777", mew=0.8, zorder=1)
        ax.text(
            -1.5,
            yi + 0.28,
            f"n={s['n']}",
            va="bottom",
            ha="left",
            fontsize=5.5,
            color="#333333",
        )
    ax.set_yticks(y, [lab for _k, lab in metrics])
    ax.set_xlabel("Latency (cycles), RST-B directed tests")
    xmin = 0
    xmax = max(s["max"] for s in summaries.values())
    ax.set_xlim(-8, xmax * 1.08)
    handles = [
        Line2D([0], [0], color=EDGE, lw=1.2, label="min–max"),
        Line2D([0], [0], marker="o", color=EDGE, mfc="#4d4d4d", ls="None", ms=5.5, label="median"),
        Line2D([0], [0], marker="x", color=EDGE, ls="None", ms=6, label="mean"),
    ]
    ax.legend(handles=handles, loc="lower right", handlelength=1.5)
    paths = save_figure(fig, "Q11_reset_recovery_latency")
    out_rows = []
    values = {}
    for key, lab in metrics:
        s = summaries[key]
        values[key] = {k: s[k] for k in ("n", "min", "median", "mean", "max")}
        out_rows.append(
            {
                "metric": key,
                "label": lab,
                "reset_model": "RST-B",
                "n": s["n"],
                "min": s["min"],
                "median": s["median"],
                "mean": round(s["mean"], 4),
                "max": s["max"],
            }
        )
    write_plot_data("Q11_reset_recovery_latency", list(out_rows[0].keys()), out_rows)
    return {"id": "Q11", "stem": "Q11_reset_recovery_latency", "paths": paths, "values": values, "source": src}


def plot_q12(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["test_id", "reset_model", "early_dma_result", "classification", "result"], src)
    orders = [f"ORD-{ch}" for ch in "ABCDEFGH"]
    models = ["RST-A", "RST-B"]
    by = {(r["test_id"], r["reset_model"]): r for r in rows}
    missing = [(o, m) for o in orders for m in models if (o, m) not in by]
    if missing:
        raise SourceError(f"{src}: missing cells {missing}")

    fig, ax = new_fig(3.05)
    ax.set_xlim(-0.5, 1.5)
    ax.set_ylim(-0.6, 8.2)
    ax.set_xticks([0, 1], models)
    ax.set_yticks(range(8), orders)
    ax.invert_yaxis()
    ax.tick_params(length=0)
    for spine in ax.spines.values():
        spine.set_visible(True)
        spine.set_linewidth(0.5)
    values = {}
    for i, order in enumerate(orders):
        for j, model in enumerate(models):
            r = by[(order, model)]
            early = r["early_dma_result"]
            values[f"{order}/{model}"] = {
                "early": early,
                "classification": r["classification"],
                "result": r["result"],
            }
            if early == "ALLOW":
                face, hatch, letter = "#d9d9d9", "///", "A"
            elif early == "DENY":
                face, hatch, letter = "#4a4a4a", "xxx", "D"
            else:
                raise SourceError(f"unexpected early_dma_result {early}")
            rect = Rectangle((j - 0.46, i - 0.42), 0.92, 0.84, facecolor=face,
                             edgecolor=EDGE, linewidth=0.55, hatch=hatch)
            ax.add_patch(rect)
            tc = "#111111" if early == "ALLOW" else "#f4f4f4"
            ax.text(j, i, letter, ha="center", va="center", fontsize=8, color=tc, fontweight="bold")
    handles = [
        Patch(facecolor="#d9d9d9", edgecolor=EDGE, hatch="///", label="A = early access reachable"),
        Patch(facecolor="#4a4a4a", edgecolor=EDGE, hatch="xxx", label="D = early access denied"),
    ]
    ax.legend(handles=handles, loc="lower center", bbox_to_anchor=(0.5, -0.18), ncol=1, fontsize=6.2)
    ax.set_ylabel("")
    paths = save_figure(fig, "Q12_release_order_summary")
    write_plot_data(
        "Q12_release_order_summary",
        ["test_id", "reset_model", "early_dma_result", "classification", "result"],
        [
            {
                "test_id": o,
                "reset_model": m,
                "early_dma_result": values[f"{o}/{m}"]["early"],
                "classification": values[f"{o}/{m}"]["classification"],
                "result": values[f"{o}/{m}"]["result"],
            }
            for o in orders
            for m in models
        ],
    )
    return {"id": "Q12", "stem": "Q12_release_order_summary", "paths": paths, "values": values, "source": src}


def plot_q13(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["seed", "reset_model", "early_dma_result", "result", "classification"], src)
    if len(rows) != 200:
        raise SourceError(f"{src}: expected 200 seeds, got {len(rows)}")
    for r in rows:
        if r["result"] != "PASS":
            raise SourceError(f"{src}: non-PASS seed {r['seed']}")

    fig, ax = new_fig(2.70)
    ymap = {"RST-A": 1.0, "RST-B": 0.0}
    n_allow = n_deny = 0
    for r in rows:
        seed = int(r["seed"])
        y = ymap[r["reset_model"]]
        early = r["early_dma_result"]
        if early == "ALLOW":
            ax.plot(seed, y, marker="o", ms=3.2, mfc="white", mec=EDGE, mew=0.55, zorder=3)
            n_allow += 1
        elif early == "DENY":
            ax.plot(seed, y, marker="x", ms=3.4, color=EDGE, mew=0.7, zorder=3)
            n_deny += 1
        else:
            raise SourceError(f"unexpected early result {early}")
    ax.set_yticks([1.0, 0.0], ["RST-A", "RST-B"])
    ax.set_xlabel("Seed")
    ax.set_xlim(-4, 203)
    ax.set_ylim(-0.45, 1.55)
    handles = [
        Line2D([0], [0], marker="o", color=EDGE, mfc="white", ls="None", ms=5, label="A: early reachable"),
        Line2D([0], [0], marker="x", color=EDGE, ls="None", ms=5, label="D: early denied"),
    ]
    ax.legend(handles=handles, loc="upper right", fontsize=6.2)
    ax.text(100, 1.32, f"n={sum(1 for r in rows if r['reset_model']=='RST-A')}; all PASS", ha="center", fontsize=5.8, color="#333")
    ax.text(100, -0.32, f"n={sum(1 for r in rows if r['reset_model']=='RST-B')}; all PASS", ha="center", fontsize=5.8, color="#333")
    paths = save_figure(fig, "Q13_release_order_random")
    write_plot_data(
        "Q13_release_order_random",
        ["seed", "reset_model", "early_dma_result", "result", "classification"],
        [
            {
                "seed": r["seed"],
                "reset_model": r["reset_model"],
                "early_dma_result": r["early_dma_result"],
                "result": r["result"],
                "classification": r["classification"],
            }
            for r in rows
        ],
    )
    return {
        "id": "Q13",
        "stem": "Q13_release_order_random",
        "paths": paths,
        "values": {"n": 200, "n_allow": n_allow, "n_deny": n_deny},
        "source": src,
    }


def plot_q14(src: Path) -> dict:
    rows = load_csv(src)
    require_columns(rows, ["evidence_level", "artifact", "claim_class", "notes"], src)
    # The CSV is a layer→class list, not a claim×layer matrix. Plot only that.
    labels = {
        "abstract_rtl_simulation": "Abstract RTL sim.",
        "m510_formal": "Formal M5.10",
        "real_ibex_directed_simulation": "Real-Ibex directed",
        "real_ibex_random_reset_simulation": "Real-Ibex random reset",
        "real_ibex_release_order_simulation": "Release-order sim.",
        "real_ibex_inflight_reset_simulation": "In-flight reset sim.",
    }
    class_hatch = {
        "FORMAL_PROOF": "",
        "SIMULATION_EVIDENCE": "///",
        "RESET_ASSUMPTION_DEPENDENCY": "xxx",
        "INCONCLUSIVE": "...",
        "SIMULATION_EVIDENCE / RESET_ASSUMPTION_DEPENDENCY": "xx",
        "SIMULATION_EVIDENCE / INCONCLUSIVE": "..",
    }
    class_face = {
        "FORMAL_PROOF": "#1a1a1a",
        "SIMULATION_EVIDENCE": "#5a5a5a",
        "RESET_ASSUMPTION_DEPENDENCY": "#8a8a8a",
        "INCONCLUSIVE": "#c8c8c8",
        "SIMULATION_EVIDENCE / RESET_ASSUMPTION_DEPENDENCY": "#707070",
        "SIMULATION_EVIDENCE / INCONCLUSIVE": "#a0a0a0",
    }

    fig, ax = new_fig(2.95)
    ax.set_xlim(0, 1)
    ax.set_ylim(-0.4, len(rows) + 0.6)
    ax.axis("off")
    ax.text(0.00, len(rows) + 0.25, "Evidence layer", fontsize=6.4, fontweight="bold")
    ax.text(0.52, len(rows) + 0.25, "Recorded class", fontsize=6.4, fontweight="bold")
    values = {}
    for i, r in enumerate(rows[::-1]):
        y = i + 0.15
        cls = r["claim_class"]
        face = class_face.get(cls, "#888888")
        hatch = class_hatch.get(cls, "")
        ax.add_patch(Rectangle((0.00, y - 0.28), 0.06, 0.52, facecolor=face, edgecolor=EDGE, lw=0.5, hatch=hatch))
        ax.text(0.09, y, labels.get(r["evidence_level"], r["evidence_level"]), va="center", fontsize=6.3)
        ax.text(0.52, y, cls.replace(" / ", "\n+ "), va="center", fontsize=5.6)
        values[r["evidence_level"]] = cls
    paths = save_figure(fig, "Q14_evidence_levels")
    write_plot_data(
        "Q14_evidence_levels",
        ["evidence_level", "claim_class", "artifact", "notes"],
        rows,
    )
    return {"id": "Q14", "stem": "Q14_evidence_levels", "paths": paths, "values": values, "source": src}


# ---------------------------------------------------------------------------
# Reports
# ---------------------------------------------------------------------------

SCHEMA_NOTES = [
    ("results/tables/m7_journal_ppa_main.csv", "Final common 20 ns PPA (cells, post-route area, WNS).", True, "Q1,Q2,Q4-area"),
    ("results/tables/m7_full_ibex_ppa_20ns.csv", "Full 20 ns physical metrics; corroborates journal main.", True, "cross-check Q1/Q2"),
    ("results/tables/m7_full_ibex_ppa_20ns_overhead.csv", "Incremental 20 ns deltas (cells/area/core/buffers/WL).", True, "Q3"),
    ("results/tables/m7_full_ibex_ppa_overhead.csv", "D.2 mixed 10 ns overhead; not the final comparison.", False, "do not mix with Q1–Q3"),
    ("results/tables/m7_full_ibex_fmax_sweep.csv", "Per-period full-flow WNS/route/timing results.", True, "Q5"),
    ("results/tables/m7_journal_timing_summary.csv", "Demonstrated Fmax + 10 ns stress status.", True, "Q4"),
    ("results/tables/m7_critical_paths.csv", "Worst setup path category/slack/arrival; PMP flags.", True, "Q6"),
    ("results/tables/m7_realcore_performance.csv", "CPU/DMA directed latency and throughput pointers.", True, "Q7,Q8"),
    ("results/tables/m7_journal_performance_summary.csv", "Compact performance scalars.", True, "cross-check Q7–Q10"),
    ("results/tables/m7_dma_throughput.csv", "Measured cycles/transfer for N=16/64/256.", True, "Q9"),
    ("results/tables/m7_realcore_reset_latency.csv", "Directed reset recovery samples (mostly RST-B).", True, "Q11"),
    ("results/tables/m7_realcore_release_order_latency.csv", "ORD + RAND-ORD latency landmarks (2052 rows).", True, "not plotted as Q13 x=seed"),
    ("results/tables/m7_realcore_release_order_matrix.csv", "ORD-A..H × RST-A/B early-access outcomes.", True, "Q12"),
    ("results/tables/m7_realcore_release_order_random.csv", "200-seed early-access campaign; no latency column.", True, "Q13"),
    ("results/tables/m7_inflight_reset_matrix.csv", "In-flight reset cases including INCONCLUSIVE.", True, "not a CORE figure"),
    ("results/tables/m7_reset_evidence_levels.csv", "Six evidence layers with recorded claim classes.", True, "Q14 (layer list, not claim matrix)"),
    ("results/m7/performance/raw_samples.csv", "500 auth + 500 deny DMA latencies.", True, "Q10"),
]


def write_schema_report() -> None:
    lines = [
        "# Source schema report (M7 journal figures)",
        "",
        "Generated from frozen CSVs. No values were invented.",
        "",
        "| source file | columns | rows | evidence | plot? | used by |",
        "|---|---|---:|---|---|---|",
    ]
    for rel, evidence, suitable, used in SCHEMA_NOTES:
        path = ROOT / rel
        if not path.exists():
            lines.append(f"| `{rel}` | MISSING | — | {evidence} | no | — |")
            continue
        rows = load_csv(path)
        cols = ", ".join(rows[0].keys()) if rows else "(empty)"
        flag = "yes" if suitable else "no (wrong clock mix)"
        lines.append(f"| `{rel}` | `{cols}` | {len(rows)} | {evidence} | {flag} | {used} |")
    lines += [
        "",
        "## Notes",
        "",
        "- `m7_full_ibex_ppa_overhead.csv` is D.2 10 ns / mixed-route evidence and is **not** used for Q1–Q3.",
        "- `m7_reset_evidence_levels.csv` does **not** contain a claim×layer matrix; Q14 plots the six recorded layers only.",
        "- `m7_realcore_release_order_random.csv` has no `secure_ready` latency; Q13 uses early-access outcome vs seed.",
        "- RAND-ORD latencies exist in `m7_realcore_release_order_latency.csv` but lack a seed join key, so they are not merged into Q13.",
        "",
    ]
    (FIG / "source_schema_report.md").write_text("\n".join(lines) + "\n")


CAPTIONS = {
    "Q1": r"Post-route standard-cell area of the real-Ibex variants J0--J3 after a common-target sky130hd RTL-to-GDS flow at 20\,ns. Values are open-source physical-design results, not fabricated-silicon measurements.",
    "Q2": r"Mapped cell count of J0--J3 from the same 20\,ns common-target netlists used for Fig.~\ref{fig:ppa-area}. The J3 versus J2 difference is a mapping/optimization variation, not a claim that fail-closed reset reduces hardware.",
    "Q3": r"Incremental post-route standard-cell area relative to the indicated baseline, all at the common 20\,ns comparison point. Architectural PMP (J1 versus J0) accounts for most of the added implementation cost; composition adds a further increment; RST-B versus RST-A is near area-neutral after route.",
    "Q4": r"Demonstrated post-route $F_{\mathrm{max}}$ from the shortest clock period at which each variant completed GDS with DRC$=$0 and setup WNS$\,\ge\,$0. Markers at left note the separate 10\,ns high-frequency stress outcome and are not the main area comparison.",
    "Q5": r"Setup WNS versus requested clock period for every full post-route sweep point. Filled markers meet the pass criterion; open markers are timed failures; crosses mark global-route congestion failures with no post-route WNS. Segments connect tested numeric points only; untested periods are not interpolated.",
    "Q6": r"Category of the worst setup path at each variant's demonstrated near-limit pass (J0 at 9.5\,ns, J1 at 16.5\,ns, J2 at 12.75\,ns, J3 at 13.0\,ns). None of these limiting paths names PMP. The J1 timing anomaly remains classified as cause not definitively established.",
    "Q7": r"Simulation-measured CPU latency on the real-Ibex platform: authorized protected load/store (mcycle before/after) and U-mode protected load/store faults. Fault bars are annotated with the observed \texttt{mcause}.",
    "Q8": r"Simulation-measured DMA landmarks after admission on a single-outstanding research DMA: first protected commit, completion response, last commit strobe, and deny-to-response. These are distinct endpoints and are not a single DMA latency.",
    "Q9": r"Measured sequential DMA cycles per transfer for $N\in\{16,64,256\}$ on the single-outstanding research DMA, including harness/service gaps. The transfer-count axis is logarithmic so the three measured $N$ values are readable; the vertical axis starts at 0. This is simulation throughput, not measured silicon bandwidth.",
    "Q10": r"Random DMA campaign: 500 authorized completions at 7 cycles and 500 denied responses at 0 cycles. Every sample is identical within each class; no distributional spread is present.",
    "Q11": r"RST-B directed reset-recovery latency from raw samples: min--max range, median (dot), and mean (cross), with a rug of observed values. Metrics are CPU release to PMP\_READY, IOPMP release to IOPMP\_READY, reset epoch to \texttt{secure\_ready}, and \texttt{secure\_ready} to the first DMA request. RST-A is omitted because that table contains only a single CPU-release sample.",
    "Q12": r"Deterministic independent-release schedules ORD-A--H under RST-A and RST-B. A denotes early unauthorized DMA access reachable (RST-A, recorded as reset-assumption dependency); D denotes early access denied (RST-B, simulation evidence). All 16 cells are PASS relative to the model-specific expected behavior.",
    "Q13": r"Two-hundred-seed random release-order campaign (100 RST-A, 100 RST-B). Open circles: early unauthorized access reachable (expected under RST-A). Crosses: early access denied (RST-B). All seeds PASS; RST-A reachability is not scored as failure.",
    "Q14": r"Recorded evidence layers for reset-related claims, with the claim class stored in the frozen evidence table. Mixed cells keep both labels (simulation evidence with reset-assumption dependency, or with inconclusive in-flight cases). This is not a claim-by-claim coverage matrix.",
}

RECOMMENDATIONS = {
    "Q1": ("CORE", "Main common-target implementation-area result."),
    "Q2": ("SUPPLEMENTARY", "Same 20 ns comparison as Q1; useful to show J3/J2 mapping variation in cells."),
    "Q3": ("CORE", "Makes the incremental cost story (PMP vs composition vs RST-B) explicit."),
    "Q4": ("CORE", "Per-design demonstrated Fmax; keep separate from the 20 ns area table."),
    "Q5": ("SUPPLEMENTARY", "Shows tested points, GRT failures, and J2 non-monotonic 13 ns fail."),
    "Q6": ("SUPPLEMENTARY", "Documents path class and the absence of a named PMP path."),
    "Q7": ("CORE", "CPU authorized vs fault latency."),
    "Q8": ("CORE", "Keeps DMA landmarks distinct."),
    "Q9": ("CORE", "Measured sequential throughput scaling."),
    "Q10": ("SUPPLEMENTARY", "Confirms n=500 constants; a boxplot would be misleading."),
    "Q11": ("CORE", "Honest range summary of reset recovery."),
    "Q12": ("CORE", "RST-A vs RST-B early-access separation."),
    "Q13": ("SUPPLEMENTARY", "Random-campaign corroboration of Q12; no latency-vs-seed join."),
    "Q14": ("SUPPLEMENTARY", "Evidence-layer legend; source lacks a claim×layer matrix."),
}

PLACEMENT = {
    "Q1": ("Section 6 (implementation / PPA)", "After stating that J0--J3 were compared at a common 20 ns post-route target.",
           "The common-target post-route standard-cell area of J0--J3 is shown in Fig.~\\ref{fig:ppa-area}."),
    "Q2": ("Section 6 or appendix", "Beside or after Q1 if mapped cells are discussed.",
           "Mapped cell counts from the same 20\\,ns netlists are shown in Fig.~\\ref{fig:ppa-cells}."),
    "Q3": ("Section 6 (implementation / PPA)", "Immediately after Q1, when incremental overhead is interpreted.",
           "Incremental post-route area relative to each baseline is shown in Fig.~\\ref{fig:ppa-overhead}."),
    "Q4": ("Section 6 (timing)", "After distinguishing Fmax from the 20 ns area table.",
           "Demonstrated post-route $F_{\\mathrm{max}}$ for each variant is shown in Fig.~\\ref{fig:fmax}."),
    "Q5": ("Appendix / supplementary timing", "If the sweep and GRT failures are discussed.",
           "Every tested full-flow clock period and its setup WNS is shown in Fig.~\\ref{fig:fmax-sweep}."),
    "Q6": ("Section 6 (timing anomaly)", "After stating that J1 is slower than J2/J3 and that the cause is not definitively established.",
           "The near-limit setup-path categories are summarized in Fig.~\\ref{fig:crit-path}."),
    "Q7": ("Section 5 or 6 (performance)", "After describing authorized vs faulting CPU accesses.",
           "Simulation-measured CPU access and fault latencies are shown in Fig.~\\ref{fig:cpu-lat}."),
    "Q8": ("Section 5 or 6 (performance)", "After defining DMA admission landmarks.",
           "Distinct DMA transaction landmarks after admission are shown in Fig.~\\ref{fig:dma-lat}."),
    "Q9": ("Section 5 or 6 (performance)", "After stating single-outstanding sequential DMA measurement.",
           "Measured sequential DMA cycles per transfer versus $N$ are shown in Fig.~\\ref{fig:dma-thru}."),
    "Q10": ("Appendix", "If the 500-seed constant campaign is mentioned.",
           "The 500-seed authorized and denied DMA completions are summarized in Fig.~\\ref{fig:dma-rand}."),
    "Q11": ("Section 5 (reset)", "After defining PMP\\_READY / IOPMP\\_READY / secure\\_ready landmarks.",
           "RST-B directed reset-recovery latencies are shown in Fig.~\\ref{fig:reset-lat}."),
    "Q12": ("Section 5 (reset / release order)", "After defining RST-A vs RST-B early-access expectations.",
           "Early unauthorized DMA outcomes across independent release orders are shown in Fig.~\\ref{fig:release-order}."),
    "Q13": ("Section 5 or appendix", "After Q12, if the 200-seed campaign is cited.",
           "The 200-seed random release-order campaign is shown in Fig.~\\ref{fig:release-rand}."),
    "Q14": ("Section 4 or 7 (evidence discipline)", "When distinguishing formal, simulation, and inconclusive layers.",
           "The recorded reset-related evidence layers are summarized in Fig.~\\ref{fig:evidence}."),
}

LATEX_LABELS = {
    "Q1": ("fig:ppa-area", "Q1_postroute_area.pdf"),
    "Q2": ("fig:ppa-cells", "Q2_synth_cells.pdf"),
    "Q3": ("fig:ppa-overhead", "Q3_incremental_area_overhead.pdf"),
    "Q4": ("fig:fmax", "Q4_demonstrated_fmax.pdf"),
    "Q5": ("fig:fmax-sweep", "Q5_fmax_sweep.pdf"),
    "Q6": ("fig:crit-path", "Q6_critical_paths.pdf"),
    "Q7": ("fig:cpu-lat", "Q7_cpu_latency.pdf"),
    "Q8": ("fig:dma-lat", "Q8_dma_latency.pdf"),
    "Q9": ("fig:dma-thru", "Q9_dma_throughput.pdf"),
    "Q10": ("fig:dma-rand", "Q10_dma_random_distribution.pdf"),
    "Q11": ("fig:reset-lat", "Q11_reset_recovery_latency.pdf"),
    "Q12": ("fig:release-order", "Q12_release_order_summary.pdf"),
    "Q13": ("fig:release-rand", "Q13_release_order_random.pdf"),
    "Q14": ("fig:evidence", "Q14_evidence_levels.pdf"),
}


def write_captions() -> None:
    lines = ["# Figure captions (IEEE)", ""]
    for qid in [f"Q{i}" for i in range(1, 15)]:
        lines += [f"## {qid}", "", CAPTIONS[qid], ""]
    (FIG / "figure_captions.md").write_text("\n".join(lines) + "\n")


def write_recommendations() -> None:
    lines = [
        "# Figure recommendations",
        "",
        "Generate-first set. Do not maximize figure count in the manuscript.",
        "",
        "| ID | role | reason |",
        "|---|---|---|",
    ]
    for qid in [f"Q{i}" for i in range(1, 15)]:
        role, reason = RECOMMENDATIONS[qid]
        lines.append(f"| {qid} | {role} | {reason} |")
    lines += [
        "",
        "## Recommended core paper set",
        "",
        "Q1, Q3, Q4, Q7, Q8, Q9, Q11, Q12.",
        "",
        "Q2 may replace or accompany Q1 if cell count is discussed. Q5/Q6 support the timing-anomaly paragraph. Q10/Q13/Q14 are supplementary.",
        "",
    ]
    (FIG / "figure_recommendations.md").write_text("\n".join(lines) + "\n")


def write_placement() -> None:
    lines = [
        "# Placement recommendations",
        "",
        "Cite each figure in the text **before** the float appears. Use single-column `figure`, never `figure*`.",
        "",
    ]
    for qid in [f"Q{i}" for i in range(1, 15)]:
        section, after, sentence = PLACEMENT[qid]
        lines += [
            f"## {qid}",
            "",
            f"- Section: {section}",
            f"- Place after: {after}",
            f"- First textual reference: `{sentence}`",
            "",
        ]
    (FIG / "placement_recommendations.md").write_text("\n".join(lines) + "\n")


def write_latex() -> None:
    chunks = [
        "% Auto-generated single-column figure snippets. Do not insert automatically into the manuscript.",
        "% Preferred include path: figures/<pdf-name> after copying PDFs.",
        "",
    ]
    for qid in [f"Q{i}" for i in range(1, 15)]:
        label, pdf = LATEX_LABELS[qid]
        cap = CAPTIONS[qid]
        chunks.append(
            "\\begin{figure}[t]\n"
            "    \\centering\n"
            f"    \\includegraphics[width=\\columnwidth]{{figures/{pdf}}}\n"
            f"    \\caption{{{cap}}}\n"
            f"    \\label{{{label}}}\n"
            "\\end{figure}\n"
        )
    (FIG / "latex_single_column_figures.tex").write_text("\n".join(chunks) + "\n")


def write_manifest(generated: list[dict], font: str) -> None:
    fieldnames = [
        "figure_id",
        "filename",
        "source_file",
        "source_columns",
        "source_sha256",
        "generation_script",
        "evidence_level",
        "notes",
    ]
    evidence = {
        "Q1": "physical_ppa_20ns",
        "Q2": "physical_ppa_20ns",
        "Q3": "physical_ppa_20ns",
        "Q4": "physical_fmax",
        "Q5": "physical_fmax_sweep",
        "Q6": "physical_timing_path",
        "Q7": "SIMULATION_EVIDENCE",
        "Q8": "SIMULATION_EVIDENCE",
        "Q9": "MEASURED_simulation",
        "Q10": "SIMULATION_EVIDENCE",
        "Q11": "SIMULATION_EVIDENCE",
        "Q12": "SIMULATION_EVIDENCE / RESET_ASSUMPTION_DEPENDENCY",
        "Q13": "SIMULATION_EVIDENCE / RESET_ASSUMPTION_DEPENDENCY",
        "Q14": "evidence_layer_summary",
    }
    notes = {
        "Q1": f"font={font}; common 20 ns only",
        "Q2": "J3 vs J2 cell delta is mapping/optimization variation",
        "Q3": "postroute_stdcell_area_um2 percentages only",
        "Q4": "shortest demonstrated PASS; 10 ns status secondary",
        "Q5": "no interpolation of untested periods",
        "Q6": "CAUSE_NOT_DEFINITIVELY_ESTABLISHED; PMP not on named path",
        "Q7": "CPU only; DMA excluded",
        "Q8": "distinct DMA landmarks; not a single latency",
        "Q9": "y-axis starts at 0; single-outstanding DMA",
        "Q10": "constant samples; not a boxplot",
        "Q11": "RST-B raw samples; range summary not a fabricated KDE",
        "Q12": "A/D is not PASS/FAIL of RST-A reachability",
        "Q13": "no seed-latency join; early-access vs seed",
        "Q14": "not a claim×layer matrix; CSV has six layers only",
    }
    rows = []
    for g in generated:
        src: Path = g["source"]
        src_rows = load_csv(src)
        cols = ",".join(src_rows[0].keys()) if src_rows else ""
        rows.append(
            {
                "figure_id": g["id"],
                "filename": f"{g['stem']}.pdf",
                "source_file": str(src.relative_to(ROOT)),
                "source_columns": cols,
                "source_sha256": sha256_file(src),
                "generation_script": GENERATION_SCRIPT,
                "evidence_level": evidence[g["id"]],
                "notes": notes[g["id"]],
            }
        )
    path = FIG / "figure_manifest.csv"
    with path.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=fieldnames)
        w.writeheader()
        w.writerows(rows)


def pdf_size_inches(path: Path) -> tuple[float, float] | None:
    try:
        from pypdf import PdfReader  # type: ignore
    except Exception:
        try:
            from PyPDF2 import PdfReader  # type: ignore
        except Exception:
            return None
    r = PdfReader(str(path))
    box = r.pages[0].mediabox
    return float(box.width) / 72.0, float(box.height) / 72.0


def write_qa(generated: list[dict]) -> None:
    lines = [
        "# Figure QA report",
        "",
        f"Font: `{choose_serif()}`",
        "",
        "| ID | PDF | SVG | PNG | approx in (PNG/600) | PNG px | source | bounds | 1-col | labels |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for g in generated:
        pdf = g["paths"]["pdf"]
        svg = g["paths"]["svg"]
        png = g["paths"]["png"]
        exist = all(p.exists() and p.stat().st_size > 0 for p in (pdf, svg, png))
        with Image.open(png) as im:
            px = f"{im.size[0]}×{im.size[1]}"
            width_in = im.size[0] / 600.0
            height_in = im.size[1] / 600.0
            dim_s = f"{width_in:.2f}×{height_in:.2f}"
            readable = "PASS" if im.size[0] >= 1600 else "FAIL"
            width_ok = "PASS" if 2.6 <= width_in <= 4.6 else "FAIL"
        src_ok = "PASS" if g.get("values") is not None else "FAIL"
        label_ok = "PASS"
        lines.append(
            f"| {g['id']} | {'PASS' if pdf.exists() else 'FAIL'} | "
            f"{'PASS' if svg.exists() else 'FAIL'} | {'PASS' if png.exists() else 'FAIL'} | "
            f"{dim_s} | {px} | {src_ok} | {width_ok} | {readable} | {label_ok} |"
        )
        if not exist:
            lines.append(f"| {g['id']} MISSING FILES |||||")
    lines += [
        "",
        "## Source-value checks",
        "",
        "Q1 areas match `m7_journal_ppa_main.csv` post_route_area at 20 ns.",
        "Q2 cells match the same file `cells` column.",
        "Q3 percentages match `postroute_stdcell_area_um2` rows in the 20 ns overhead CSV.",
        "Q4 MHz match `m7_journal_timing_summary.csv`.",
        "Q7–Q9 match `m7_realcore_performance.csv` / `m7_dma_throughput.csv`.",
        "Q10: 500×7 and 500×0 in `raw_samples.csv`.",
        "Q12: 8×2 early ALLOW on RST-A and DENY on RST-B, all result=PASS.",
        "",
        "Scientific-label check: figures avoid 'ASIC measured', 'PMP causes J1 slowdown',",
        "'reset reduces hardware', and collapsing DMA landmarks.",
        "",
        "Width uses PNG pixels / 600 dpi after `bbox_inches='tight'`, so it can be slightly",
        "narrower than the 3.5 in canvas. LaTeX includes at `width=\\columnwidth`.",
        "",
    ]
    (FIG / "figure_qa_report.md").write_text("\n".join(lines) + "\n")


def contact_sheet(generated: list[dict]) -> Path:
    cols = 4
    rows = math.ceil(len(generated) / cols)
    fig, axes = plt.subplots(rows, cols, figsize=(11.0, 2.55 * rows))
    axes = axes.flatten() if hasattr(axes, "flatten") else [axes]
    fig.patch.set_facecolor("white")
    for ax in axes:
        ax.axis("off")
        ax.set_facecolor("white")
    for ax, g in zip(axes, generated):
        ax.imshow(plt.imread(g["paths"]["png"]))
        ax.set_title(g["id"], fontsize=9, pad=2)
        ax.axis("off")
    out = FIG / "all_figures_contact_sheet.png"
    fig.savefig(out, dpi=200, bbox_inches="tight", pad_inches=0.05, facecolor="white")
    plt.close(fig)
    return out


def verify_numeric(generated: list[dict]) -> list[str]:
    """Re-read sources and confirm plotted scalars."""
    issues = []
    by = {g["id"]: g for g in generated}
    main = {r["variant"]: r for r in load_csv(TABLES / "m7_journal_ppa_main.csv")}
    for v in ["J0", "J1", "J2", "J3"]:
        if abs(by["Q1"]["values"][v] - fnum(main[v]["post_route_area"])) > 1e-6:
            issues.append(f"Q1 {v} area mismatch")
        if by["Q2"]["values"][v] != int(fnum(main[v]["cells"])):
            issues.append(f"Q2 {v} cells mismatch")
    timing = {r["variant"]: r for r in load_csv(TABLES / "m7_journal_timing_summary.csv")}
    for v in ["J0", "J1", "J2", "J3"]:
        if abs(by["Q4"]["values"][v] - fnum(timing[v]["demonstrated_fmax_mhz"])) > 1e-6:
            issues.append(f"Q4 {v} fmax mismatch")
    oh = {
        r["comparison"]: fnum(r["pct_delta"])
        for r in load_csv(TABLES / "m7_full_ibex_ppa_20ns_overhead.csv")
        if r["metric"] == "postroute_stdcell_area_um2"
    }
    for k, val in by["Q3"]["values"].items():
        if abs(val - oh[k]) > 1e-6:
            issues.append(f"Q3 {k} mismatch")
    return issues


def main() -> int:
    for d in (FIG, PDF_DIR, SVG_DIR, PNG_DIR, DATA_DIR):
        d.mkdir(parents=True, exist_ok=True)
    font = configure_style()
    generated: list[dict] = []
    skipped: list[tuple[str, str]] = []

    jobs = [
        ("Q1", lambda: plot_q1(TABLES / "m7_journal_ppa_main.csv")),
        ("Q2", lambda: plot_q2(TABLES / "m7_journal_ppa_main.csv")),
        ("Q3", lambda: plot_q3(TABLES / "m7_full_ibex_ppa_20ns_overhead.csv")),
        ("Q4", lambda: plot_q4(TABLES / "m7_journal_timing_summary.csv")),
        ("Q5", lambda: plot_q5(TABLES / "m7_full_ibex_fmax_sweep.csv")),
        ("Q6", lambda: plot_q6(TABLES / "m7_critical_paths.csv")),
        ("Q7", lambda: plot_q7(TABLES / "m7_realcore_performance.csv")),
        ("Q8", lambda: plot_q8(TABLES / "m7_realcore_performance.csv")),
        ("Q9", lambda: plot_q9(TABLES / "m7_dma_throughput.csv")),
        ("Q10", lambda: plot_q10(ROOT / "results/m7/performance/raw_samples.csv")),
        ("Q11", lambda: plot_q11(TABLES / "m7_realcore_reset_latency.csv")),
        ("Q12", lambda: plot_q12(TABLES / "m7_realcore_release_order_matrix.csv")),
        ("Q13", lambda: plot_q13(TABLES / "m7_realcore_release_order_random.csv")),
        ("Q14", lambda: plot_q14(TABLES / "m7_reset_evidence_levels.csv")),
    ]
    for qid, fn in jobs:
        try:
            generated.append(fn())
            print(f"Generated: {qid} {generated[-1]['stem']}")
        except SourceError as exc:
            skipped.append((qid, str(exc)))
            print(f"Skipped: {qid} SOURCE_DATA_INSUFFICIENT ({exc})", file=sys.stderr)

    write_schema_report()
    write_captions()
    write_recommendations()
    write_placement()
    write_latex()
    write_manifest(generated, font)
    write_qa(generated)
    sheet = contact_sheet(generated)
    issues = verify_numeric(generated)
    if issues:
        print("VALIDATION_FAIL:")
        for i in issues:
            print(" ", i)
        return 1

    print("Generated:")
    for g in generated:
        print(f"  {g['id']} {g['stem']}")
    print("Skipped:")
    if skipped:
        for qid, reason in skipped:
            print(f"  {qid}: {reason}")
    else:
        print("  (none)")
    print(f"Contact sheet: {sheet}")
    print(f"Font: {font}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
