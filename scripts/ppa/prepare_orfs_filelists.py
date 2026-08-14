#!/usr/bin/env python3
"""Build ORFS-visible file lists from prepared J0-J3 manifests.

Keeps the prepared Ibex RTL file list. Drops simulation-only sources and
the accidental full OpenTitan prim/rtl dump (those extra primitives are
not Ibex dependencies and fail slang). Replaces that dump with the prim
set from Ibex's own dv/uvm/core_ibex/ibex_dv.f plus prim_generic tech
cells required by ibex_top.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path("/home/mmr/ricv_paper")
REPO_MOUNT = "/repo"
IBEX = ROOT / "third_party/ibex"
MANIFEST_DIR = ROOT / "results/m7/ppa_full/source_manifests"
OUT_DIR = ROOT / "m7/ppa/orfs/filelists"
PRIM = IBEX / "vendor/lowrisc_ip/ip/prim/rtl"
PRIM_GENERIC = IBEX / "vendor/lowrisc_ip/ip/prim_generic/rtl"

SIM_ONLY = {
    "ibex_tracer.sv",
    "ibex_tracer_pkg.sv",
    "ibex_top_tracing.sv",
    "prim_cdc_rand_delay.sv",
}

# From third_party/ibex/dv/uvm/core_ibex/ibex_dv.f (Ibex-maintained).
IBEX_DV_PRIM = [
    PRIM / "prim_assert.sv",
    PRIM / "prim_util_pkg.sv",
    PRIM / "prim_count_pkg.sv",
    PRIM / "prim_count.sv",
    PRIM / "prim_secded_pkg.sv",
    PRIM / "prim_secded_22_16_dec.sv",
    PRIM / "prim_secded_22_16_enc.sv",
    PRIM / "prim_secded_64_57_dec.sv",
    PRIM / "prim_secded_64_57_enc.sv",
    PRIM / "prim_secded_hamming_22_16_dec.sv",
    PRIM / "prim_secded_hamming_22_16_enc.sv",
    PRIM / "prim_secded_hamming_39_32_dec.sv",
    PRIM / "prim_secded_hamming_39_32_enc.sv",
    PRIM / "prim_secded_hamming_72_64_dec.sv",
    PRIM / "prim_secded_hamming_72_64_enc.sv",
    PRIM / "prim_mubi_pkg.sv",
    PRIM / "prim_ram_1p_adv.sv",
    PRIM / "prim_ram_1p_scr.sv",
    PRIM / "prim_cipher_pkg.sv",
    PRIM / "prim_lfsr.sv",
    PRIM / "prim_secded_inv_28_22_enc.sv",
    PRIM / "prim_secded_inv_28_22_dec.sv",
    PRIM / "prim_secded_inv_39_32_enc.sv",
    PRIM / "prim_secded_inv_39_32_dec.sv",
    PRIM / "prim_secded_inv_72_64_enc.sv",
    PRIM / "prim_secded_inv_72_64_dec.sv",
    PRIM / "prim_prince.sv",
    PRIM / "prim_subst_perm.sv",
    PRIM / "prim_secded_28_22_enc.sv",
    PRIM / "prim_secded_28_22_dec.sv",
    PRIM / "prim_secded_39_32_enc.sv",
    PRIM / "prim_secded_39_32_dec.sv",
    PRIM / "prim_secded_72_64_enc.sv",
    PRIM / "prim_secded_72_64_dec.sv",
]

IBEX_DV_GENERIC = [
    PRIM_GENERIC / "prim_pkg.sv",
    PRIM_GENERIC / "prim_ram_1p_pkg.sv",
    PRIM_GENERIC / "prim_ram_1p.sv",
    PRIM_GENERIC / "prim_buf.sv",
    PRIM_GENERIC / "prim_clock_mux2.sv",
    PRIM_GENERIC / "prim_flop.sv",
    PRIM_GENERIC / "prim_and2.sv",
]

# ASIC clock-gate used by official ORFS ibex; do not also add prim_generic clock_gating.
SYN_CLOCK_GATE = IBEX / "syn/rtl/prim_clock_gating.v"

# ibex_trvk.sv (in rtl/) instantiates these; keep them so slang can parse the unit.
TRVK_PRIM = [
    PRIM / "prim_fifo_sync.sv",
    PRIM / "prim_fifo_sync_cnt.sv",
]


def parse_manifest(path: Path) -> list[Path]:
    files: list[Path] = []
    for raw in path.read_text().splitlines():
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        files.append(Path(line))
    return files


def to_repo(p: Path) -> str:
    p = p.resolve()
    rel = p.relative_to(ROOT)
    return f"{REPO_MOUNT}/{rel.as_posix()}"


def is_opentitan_prim_dump(p: Path) -> bool:
    return "vendor/lowrisc_ip/ip/prim/rtl" in p.as_posix()


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    missing: list[str] = []
    extras = IBEX_DV_PRIM + IBEX_DV_GENERIC + TRVK_PRIM + [SYN_CLOCK_GATE]
    for var in ("J0", "J1", "J2", "J3"):
        src = MANIFEST_DIR / f"{var}.files"
        prepared = parse_manifest(src)
        kept: list[Path] = []
        dropped: list[str] = []
        for p in prepared:
            if not p.exists():
                if p.name == "bus_pkg.sv":
                    dropped.append(f"{p} (absent in pinned Ibex; not required)")
                    continue
                missing.append(str(p))
                continue
            if p.suffix == ".vh":
                dropped.append(f"{p.name} (include, not a compilation unit)")
                continue
            if p.name in SIM_ONLY:
                dropped.append(f"{p.name} (simulation-only)")
                continue
            if is_opentitan_prim_dump(p):
                dropped.append(f"{p.name} (not in Ibex ibex_dv.f prim set)")
                continue
            kept.append(p)
        for extra in extras:
            if extra not in kept:
                if not extra.exists():
                    missing.append(str(extra))
                else:
                    kept.append(extra)
                    dropped.append(f"ADDED {extra.name} (from ibex_dv.f / prim_generic / syn)")
        out = OUT_DIR / f"{var}.orfs.files"
        out.write_text("\n".join(to_repo(p) for p in kept) + "\n")
        note = OUT_DIR / f"{var}.filter.txt"
        note.write_text(
            f"prepared={src}\nkept={len(kept)}\nnotes:\n"
            + "\n".join(f"  {d}" for d in dropped)
            + "\n"
        )
        print(f"{var}: kept={len(kept)} notes={len(dropped)} -> {out}")
    if missing:
        raise SystemExit("missing files:\n" + "\n".join(missing))


if __name__ == "__main__":
    main()
