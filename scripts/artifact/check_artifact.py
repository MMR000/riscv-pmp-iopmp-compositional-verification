#!/usr/bin/env python3
"""Lightweight publication-artifact sanity checks. Does not run experiments."""
from __future__ import annotations

import csv
import hashlib
import os
import re
import sys
from pathlib import Path

MAX_FILE_BYTES = 95 * 1024 * 1024
WARN_FILE_BYTES = 50 * 1024 * 1024

REQUIRED = [
    "README.md",
    "PROVENANCE.md",
    "CITATION.cff",
    "SECURITY.md",
    "THIRD_PARTY_NOTICES.md",
    "docs/LICENSE_STATUS.md",
    "docs/REPRODUCIBILITY.md",
    "docs/EVIDENCE_MAP.md",
    "docs/TOOLCHAIN.md",
    "docs/FROZEN_EVIDENCE.md",
    "docs/REPOSITORY_STRUCTURE.md",
    "docs/FIGURES.md",
    "docs/WAVEFORM_REPRODUCTION.md",
    "docs/PAPER_ARTIFACT_TEXT.md",
    "results/FROZEN_EVIDENCE_MANIFEST.sha256",
    "results/README.md",
    "results/tables/m7_journal_ppa_main.csv",
    "results/tables/m7_journal_timing_summary.csv",
    "results/tables/m7_journal_performance_summary.csv",
    "results/tables/m7_full_ibex_ppa_20ns.csv",
    "results/tables/m7_full_ibex_ppa_20ns_overhead.csv",
    "results/tables/m510_guarantee_matrix.csv",
    "results/tables/m510_property_matrix.csv",
    "results/tables/m7_ibex_pmp_matrix.csv",
    "results/tables/m7_ibex_composed_matrix.csv",
    "results/tables/m7_ibex_composed_random.csv",
    "results/tables/m7_realcore_reset_matrix.csv",
    "results/tables/m7_realcore_reset_random.csv",
    "results/tables/m7_inflight_reset_matrix.csv",
    "results/tables/m7_realcore_release_order_matrix.csv",
    "results/tables/m7_realcore_release_order_random.csv",
    "results/tables/m7_reset_evidence_levels.csv",
    "results/tables/m7_if01_a_final_ledger.csv",
    "results/ieee_access_final/formal/PROOF_STATISTICS.csv",
    "results/ieee_access_final/arbiter_diff/FORMAL_VS_PRODUCTION_ARBITER.md",
    "docs/IF01_A.md",
    "docs/FINAL_FREEZE_AUDIT.md",
    "docs/CLAIM_TO_EVIDENCE.csv",
    "docs/history/README.md",
    "formal/sby/sp08_rstb_prove.sby",
    "formal/sby/prod_arbiter_v2_prove.sby",
    "formal/sby/noregrant_any_prove.sby",
    "scripts/setup/fetch_dependencies.sh",
    "scripts/figures/generate_journal_figures.py",
    "scripts/artifact/check_artifact.py",
    "third_party/README.md",
    "third_party/pins/ibex.commit",
    "third_party/pins/orfs.commit",
    "third_party/pins/orfs_docker.digest",
]

KEY_CSVS = [
    "results/tables/m7_journal_ppa_main.csv",
    "results/tables/m7_journal_timing_summary.csv",
    "results/tables/m7_journal_performance_summary.csv",
    "results/tables/m7_ibex_pmp_matrix.csv",
    "results/tables/m7_ibex_composed_matrix.csv",
    "results/tables/m7_ibex_composed_random.csv",
    "results/tables/m7_realcore_reset_random.csv",
    "results/tables/m7_realcore_release_order_random.csv",
    "results/tables/m510_guarantee_matrix.csv",
    "results/tables/m7_if01_a_final_ledger.csv",
    "results/tables/m7_inflight_reset_matrix.csv",
]

FORBIDDEN_DIR_MARKERS = [
    "third_party/ibex/.git",
    "third_party/OpenROAD-flow-scripts/.git",
    "third_party/toolchain",
    "third_party/zero-day-labs-riscv-iopmp/.git",
    "third_party/riscv-iopmp-official/.git",
]

PIN_EXPECT = {
    "third_party/pins/ibex.commit": "c61e11c1e416b9ce2d996013b444c8e558d35b2b",
    "third_party/pins/orfs.commit": "f9ec54a6de7b2bc69fd586015f6ebdab34eca69c",
    "third_party/pins/orfs_docker.digest": "sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277",
}

LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")


def repo_root() -> Path:
    here = Path(__file__).resolve()
    for p in [here.parent, *here.parents]:
        if (p / "README.md").is_file() and (p / "results" / "tables").is_dir():
            return p
    return Path.cwd()


def fail(msg: str, errors: list[str]) -> None:
    errors.append(msg)


def tracked_files(root: Path) -> list[Path]:
    git_dir = root / ".git"
    if git_dir.exists():
        import subprocess

        out = subprocess.check_output(["git", "-C", str(root), "ls-files"], text=True)
        return [root / line for line in out.splitlines() if line]
    skip = {".git", "__pycache__", ".venv"}
    files = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in skip and d != ".git"]
        for name in filenames:
            files.append(Path(dirpath) / name)
    return files


def check_required(root: Path, errors: list[str]) -> None:
    for rel in REQUIRED:
        if not (root / rel).is_file():
            fail(f"missing required file: {rel}", errors)


def check_pins(root: Path, errors: list[str]) -> None:
    for rel, expected in PIN_EXPECT.items():
        path = root / rel
        if not path.is_file():
            fail(f"missing pin file: {rel}", errors)
            continue
        got = path.read_text(encoding="utf-8").strip()
        if got != expected:
            fail(f"pin mismatch {rel}: got {got!r} expected {expected!r}", errors)


def check_csvs(root: Path, errors: list[str]) -> None:
    for rel in KEY_CSVS:
        path = root / rel
        if not path.is_file():
            fail(f"missing CSV: {rel}", errors)
            continue
        with path.open(newline="", encoding="utf-8") as fh:
            rows = list(csv.DictReader(fh))
        if not rows:
            fail(f"empty CSV: {rel}", errors)


def check_manifest(root: Path, errors: list[str]) -> None:
    manifest = root / "results" / "FROZEN_EVIDENCE_MANIFEST.sha256"
    if not manifest.is_file():
        fail("missing results/FROZEN_EVIDENCE_MANIFEST.sha256", errors)
        return
    for line in manifest.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 2:
            fail(f"malformed manifest line: {line!r}", errors)
            continue
        digest, rel = parts[0], parts[-1]
        if rel.startswith("*"):
            rel = rel[1:]
        path = root / rel
        if not path.is_file():
            fail(f"manifest path missing: {rel}", errors)
            continue
        h = hashlib.sha256(path.read_bytes()).hexdigest()
        if h != digest:
            fail(f"SHA256 mismatch: {rel}", errors)


def check_readme_links(root: Path, errors: list[str]) -> None:
    text = (root / "README.md").read_text(encoding="utf-8")
    for match in LINK_RE.finditer(text):
        target = match.group(1).strip()
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        target = target.split("#", 1)[0]
        if not target:
            continue
        if not (root / target).exists():
            fail(f"README link missing: {target}", errors)


def check_sizes(root: Path, errors: list[str], warnings: list[str]) -> None:
    for path in tracked_files(root):
        if not path.is_file():
            continue
        size = path.stat().st_size
        rel = path.relative_to(root).as_posix()
        if size > MAX_FILE_BYTES:
            fail(f"file exceeds 95 MB: {rel} ({size} bytes)", errors)
        elif size > WARN_FILE_BYTES:
            warnings.append(f"file exceeds 50 MB (needs justification): {rel} ({size} bytes)")


IOPMP_EXPECT = "dd7fe6a89f22a9c830615528733b2d51ccfb852ca0966d3991ab1172d06c82c8"
ARB_EXPECT = "204776349008176d2cc2934c0304a27497302cfbe522011ff9358dadf81b4519"


def _file_sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_final_headlines(root: Path, errors: list[str]) -> None:
    iopmp = root / "rtl/iopmp/iopmp.v"
    arb = root / "m7/rtl/m7_research_arbiter.sv"
    if iopmp.is_file() and _file_sha256(iopmp) != IOPMP_EXPECT:
        fail(f"production IOPMP hash mismatch: {_file_sha256(iopmp)}", errors)
    if arb.is_file() and _file_sha256(arb) != ARB_EXPECT:
        fail(f"production arbiter hash mismatch: {_file_sha256(arb)}", errors)

    ppa = root / "results/tables/m7_journal_ppa_main.csv"
    areas = {}
    if ppa.is_file():
        with ppa.open(newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                areas[row["variant"]] = str(int(float(row["post_route_area"])))
    if areas.get("J2") != "277641":
        fail(f"headline J2 area is {areas.get('J2')!r}, expected 277641", errors)
    if areas.get("J3") != "280331":
        fail(f"headline J3 area is {areas.get('J3')!r}, expected 280331", errors)

    oh = root / "results/tables/m7_full_ibex_ppa_20ns_overhead.csv"
    if oh.is_file():
        with oh.open(newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                if (
                    row["comparison"] == "J3_vs_J2"
                    and row["metric"] == "postroute_stdcell_area_um2"
                    and row["pct_delta"] != "0.97"
                ):
                    fail(f"headline J3/J2 pct_delta is {row['pct_delta']!r}, expected 0.97", errors)

    inflight = root / "results/tables/m7_inflight_reset_matrix.csv"
    if inflight.is_file():
        with inflight.open(newline="", encoding="utf-8") as fh:
            for row in csv.DictReader(fh):
                if row.get("test_id") == "IF01-A" and row.get("result") == "INCONCLUSIVE":
                    fail("IF01-A is still listed as current INCONCLUSIVE", errors)
                if row.get("test_id") == "IF03-C" and "err= " in row.get("observed", ""):
                    fail("IF03-C still has empty err= in current matrix", errors)

    readme = (root / "README.md").read_text(encoding="utf-8")
    if "277641" not in readme or "280331" not in readme or "+0.97%" not in readme:
        fail("README missing final J2/J3 headline 277641 / 280331 / +0.97%", errors)
    if re.search(r"J3 vs J2 \*\*\+0\.36%\*\*", readme):
        fail("README still presents +0.36% as the current J3/J2 headline", errors)
    if re.search(r"IF01-A remains `INCONCLUSIVE`", readme):
        fail("README still lists IF01-A as current INCONCLUSIVE", errors)


def check_forbidden(root: Path, errors: list[str]) -> None:
    for rel in FORBIDDEN_DIR_MARKERS:
        if (root / rel).exists():
            fail(f"forbidden third-party/toolchain path is present: {rel}", errors)


def main() -> int:
    root = repo_root()
    os.chdir(root)
    errors: list[str] = []
    warnings: list[str] = []
    check_required(root, errors)
    check_pins(root, errors)
    check_csvs(root, errors)
    check_manifest(root, errors)
    check_readme_links(root, errors)
    check_final_headlines(root, errors)
    check_sizes(root, errors, warnings)
    check_forbidden(root, errors)
    for w in warnings:
        print(f"WARNING: {w}")
    if errors:
        print("ARTIFACT CHECK FAILED")
        for e in errors:
            print(f"ERROR: {e}")
        return 1
    print(f"ARTIFACT CHECK PASS  root={root}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
