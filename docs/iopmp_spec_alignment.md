# IOPMP specification / external implementation alignment (M7 update)

Extends M5 alignment (`docs/m5_spec_alignment.md`, `docs/m5_spec_alignment.csv`).

Labels: **implemented faithfully** | **simplified** | **not implemented** | **not applicable**

## Research M4-IOPMP (`rtl/iopmp/iopmp.v`)

| Feature | Label | Notes |
|---------|-------|-------|
| Single rule0 region | simplified | |
| 8-bit requester ID | simplified | vs RRID/SRCMD tables |
| Admission-time authorization | simplified | documented in decisions.md |
| Reset defaults RST-A/B | simplified | compositional model |
| Full RISC-V IOPMP register map | not implemented | |

## REF-IOPMP (official C model)

| Feature | Label | Notes |
|---------|-------|-------|
| HWCFG0.enable semantics | implemented faithfully | M5 REF track |
| MD/SRCMD tables | not applicable | M4 adapter maps AUTH/UNAUTH |

## zero-day-labs RTL-IOPMP (`third_party/zero-day-labs-riscv-iopmp`)

| Field | Value |
|-------|-------|
| Upstream | zero-day-labs/riscv-iopmp (vendored) |
| Spec revision targeted | IOPMP v1.0.0-draft5 (per upstream README) |
| Local patches | M56 FIX-0/FIX-2 via `scripts/m56/apply_fix.sh` |
| Reset default | upstream + SoC integration dependent |
| Requester encoding | AXI NSAID / user signals (M5 adapter AUTH=1, UNAUTH=2) |
| Entries/domains | full_model configuration in M5/M56 harness |
| AXI subset | AXI4 with demux (see M57 full-RTL harness) |
| Outstanding support | AXI channel split; FIX-2 write-binding repair |

**Do not call** this integration "standards-compliant RISC-V IOPMP."

## M7 independent IOPMP synthesis comparison

See `results/tables/m7_ppa.csv` configs I0 (original) vs I1 (FIX-2 proper).
