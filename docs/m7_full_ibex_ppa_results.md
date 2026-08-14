# M7 full-Ibex PPA results (Phase D.2)

Platform: **sky130hd** only (primary table).  
Image: `openroad/orfs@sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277`.  
Ibex: `c61e11c1e416b9ce2d996013b444c8e558d35b2b`. ORFS: `f9ec54a6de7b2bc69fd586015f6ebdab34eca69c`.  
Memory: LOGIC-ONLY / MEMORY-BLACKBOX. **LEC was not performed** (container Kepler-formal needs AVX-512 on this host).

**TIMING_PASS** means post-route setup WNS ≥ 0 and TNS = 0. GDS alone is not success.  
A 10 ns TIMING_PASS demonstrates **≥ 100 MHz**, not Fmax = 100 MHz.

## Primary common-target table (10.0 ns)

| Variant | Synth cells | Synth area µm² | Place area µm² | Route area µm² | Setup WNS ns | TNS ns | Hold WNS ns | DRC | GDS | Result |
|---------|-------------:|---------------:|---------------:|---------------:|-------------:|-------:|------------:|----:|-----|--------|
| J0 PMP off | 15267 | 136480 | 155626 | 165439 | +0.082 | 0 | +0.411 | 0 | YES | TIMING_PASS |
| J1 PMP on | 25220 | 209766 | 249322 | N/A | N/A | N/A | N/A | N/A | NO | GRT congestion |
| J2 +DMA/IOPMP | 28594 | 242464 | 287311 | 304870 | −1.278 | −24.65 | +0.299 | 0 | YES | GDS, setup fail |
| J3 +RST-B | 28130 | 242663 | 288225 | N/A | N/A | N/A | N/A | N/A | NO | GRT congestion |

Raw: `results/tables/m7_full_ibex_ppa.csv`. Logs: `results/m7/ppa_full/orfs/J*/`.

## Incremental overhead (synth / place; primary 10 ns flow)

| Step | Synth cells Δ | Synth cells % | Synth area % | Place area % |
|------|-------------:|-------------:|-------------:|-------------:|
| J1−J0 architectural PMP | +9953 | +65.19 | +53.70 | +60.21 |
| J2−J1 DMA/IOPMP composition | +3374 | +13.38 | +15.59 | +15.24 |
| J3−J2 fail-closed + domain reset | −464 | −1.62 | +0.08 | +0.32 |
| J3−J0 full evaluated composition | +12863 | +84.25 | +77.80 | +85.20 |

J3 synth cell count is slightly below J2; place area is slightly above. Treat the RST-B/domain-reset increment as near ABC-mapping noise; IOPMP remains in the J3 netlist (`structural_sanity.md`).

Post-route area exists at 10 ns only for J0 and J2: 165439 → 304870 µm² (+84.28%). That mixes PMP and composition.

## Demonstrated Fmax (shortest full post-route PASS)

| Variant | Shortest PASS period | Demonstrated Fmax | Bounding FAIL |
|---------|---------------------:|------------------:|---------------|
| J0 | 9.5 ns | **105.26 MHz** | 9.0 ns setup fail |
| J1 | 20.0 ns | **50.00 MHz** | 16.0 ns setup fail; 10/15 ns GRT fail |
| J2 | 12.75 ns | **78.43 MHz** | 12.5 ns WNS ≈ −0.0007 ns |
| J3 | 13.0 ns | **76.92 MHz** | 10 ns GRT fail |

Sweep CSV: `results/tables/m7_full_ibex_fmax_sweep.csv`.  
Do not report the primary 10 ns target as Fmax.

## I0/I1 and power

I0/I1 FIX-2: **NOT_RUN**. Power: **OMITTED**.
