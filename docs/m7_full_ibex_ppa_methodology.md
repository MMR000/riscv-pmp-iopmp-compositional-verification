# M7 full-Ibex PPA methodology

## Objective

Quantify incremental **logic** implementation cost of compositional PMP–IOPMP isolation on a common open physical-design target, without altering Phase A–C.5 security evidence.

## Variants

| Variant | Definition | Increment |
|---------|------------|-----------|
| J0 | Real Ibex `PMPEnable=0`, mem shells | baseline |
| J1 | J0 + architectural PMP (`PMPEnable=1`) | J1−J0 |
| J2 | J1 + DMA + IOPMP + arbiter + adapter (RST-A) | J2−J1 |
| J3 | J2 + `RST_B` security_config + domain reset coord | J3−J2 |
| J4 | **NOT_APPLICABLE** to real-core top | I0/I1 for FIX-2 |

RTL: `m7/ppa/rtl/m7_ppa_j{0,1,2,3}_top.sv`

## Toolchain

- **Flow**: OpenROAD Flow Scripts (ORFS) pinned at `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c`
- **Primary platform**: `sky130hd`
- **Memory policy**: LOGIC-ONLY / MEMORY-BLACKBOX (`docs/m7_ppa_memory_policy.md`)
- **Constraints**: 20 ns primary period; Fmax sweep per `docs/m7_ppa_constraints.md`

## Commands

```bash
bash scripts/ppa/generate_source_manifests.sh
make m7-ppa-full
make m7-performance
```

## Evidence class

Post-route ORFS metrics = **open-source RTL-to-GDS implementation estimate**. Not ASIC signoff.

## Gate

Official ORFS `gcd` + `sky130hd/ibex` must complete before interpreting project-variant physical metrics. Current host: **PPA_TOOLCHAIN_BLOCKER** (see `results/m7/ppa_full/toolchain_validation/`).

## Reproducibility

- Source manifests: `results/m7/ppa_full/source_manifests/J*.files`
- Ibex pin: `c61e11c1e416b9ce2d996013b444c8e558d35b2b`
- Frozen security matrices: SHA256 recorded in `results/m7/ppa_full/phase_d_start.txt`
