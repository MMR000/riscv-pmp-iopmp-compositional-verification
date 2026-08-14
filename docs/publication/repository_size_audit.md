# Repository size audit

**Date:** 2026-08-14  
**Working tree:** `/home/mmr/ricv_paper`  
**HEAD (scientific freeze):** `07ee8931f8e7e75d48168914fffddb31a5e0a091`  
**Tag:** `checkpoint-m7-phase-d3-ppa-final`

## Working-tree size

| Path | Approx. size | Public snapshot |
|------|----------------|-----------------|
| Entire working tree | ~24 GB | **No** — curated subset |
| `third_party/` | ~22 GB | **No** — fetch pins only |
| `results/` | ~1 GB | Compact tables, metrics, logs; exclude sim-verilator |
| `tools/` | ~731 MB | README only (no vendored solver binaries) |
| `results/m7/realcore_reset/` | ~432 MB | Compact logs + CSVs; exclude Verilator trees |
| `results/m7/realcore_reset_c5/` | ~432 MB | Same policy |
| Git object store (`git count-objects -vH`) | ~133 MB (no packs) | Internal history is **not** pushed by default |

## Historically tracked blobs

Largest already-tracked blobs in the internal Git history are on the order of **~1.8 MB** (`results/m7/ppa_full/orfs/J1/logs/5_1_grt.json`). No historically tracked file approaches GitHub’s 100 MB limit.

## Untracked giants (must not be published)

- Verilator `*.gch` / `sim-verilator/` trees (~97 MB individual precompiled headers observed)
- `m5/obj_dir/`, `m55/obj_dir/`, `m56/obj_dir/`
- `third_party/toolchain/` (xPack GCC)
- `third_party/ibex/` full checkout and `build/`
- `third_party/OpenROAD-flow-scripts/` and PDK/tool installs
- Formal solver dumps (`model/*.smt2`, `engine_0/` traces)

## Compact scientific evidence (include)

- `results/tables/*.csv` (~644 KB total)
- Journal figures PDF/SVG (~1.5 MB)
- Selected M4 waveforms (~92 KB total; each file ≪ 20 MB)
- Compact PPA `metrics*.json`, fairness markdown, toolchain version files
- Compact Phase A/B/C/C.5 logs (excluding simulator binaries)

## Public size target

Aim: source + compact results comfortably below a few hundred MB.  
No tracked file may exceed **95 MB**. Any file **>50 MB** requires explicit justification; none are planned.
