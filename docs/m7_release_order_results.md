# M7 Phase C.5 — True Independent Release-Order Results

## Scope

Replace Phase C functional-only `RC-ORD-A..F` recovery with **independently scheduled**
releases of CPU, DMA, IOPMP, SECURITY_CONFIG, and INTERCONNECT under both RST-A and RST-B.
Protected SRAM retained (MEM-RET). No PPA.

## Method

1. Boot assist: release CPU+IC at cycle 1 (Ibex health constraint when boot RAM is live on cold `rst_ni`).
2. Seed sentinel; wait `PMP_READY`.
3. **Second reset epoch**: assert all five domains (MEM-RET stays); release at `epoch_base + REL_*`.
4. Unauthorized DMA at earliest domain-legal time; then trusted IOPMP CFG; post-ready unauth/auth DMA; U-mode CPU store after `go`.

Schedules (cpu, dma, iopmp, sec, ic) offsets from epoch:

| ID | Order intent | Offsets |
|----|--------------|---------|
| ORD-A | IOPMP → SEC → IC → CPU → DMA | (25,30,10,12,15) |
| ORD-B | CPU → IOPMP → SEC → IC → DMA | (10,30,15,18,22) |
| ORD-C | DMA → CPU → IOPMP → SEC → IC | (20,10,25,28,32) |
| ORD-D | DMA → IOPMP → SEC → IC → CPU | (30,10,15,18,22) |
| ORD-E | simultaneous | (15,15,15,15,15) |
| ORD-F | CPU → DMA → IC → SEC → IOPMP last | (10,12,30,25,18) |
| ORD-G | security last | (10,14,12,30,16) |
| ORD-H | interconnect last | (10,14,12,16,30) |

## Deterministic results

All ORD-A..H × RST-A/B: **PASS**.

- RST-A early unauth DMA: **ALLOW** → `RESET_ASSUMPTION_DEPENDENCY` (not a vulnerability claim)
- RST-B early unauth DMA: **DENY** → `SIMULATION_EVIDENCE`
- Post-ready unauth: DENY; auth: ALLOW; U-store: mcause=7

Matrix: `results/tables/m7_realcore_release_order_matrix.csv`

## Random campaign

200 reproducible seeds randomizing independent release offsets in `[8,40]`, RST-A/B alternating, replay plusargs recorded.

- 200/200 PASS
- 100 RST-A → `RESET_ASSUMPTION_DEPENDENCY` (expected early allow)
- 100 RST-B → `SIMULATION_EVIDENCE`

Raw: `results/tables/m7_realcore_release_order_random.csv`

## Latency (from stored raw)

Raw: `results/tables/m7_realcore_release_order_latency.csv`  
Summary: `results/m7/realcore_reset_c5/release_order_latency_summary.csv`

Notable (cycles, n≈216 unless noted):

| Metric | min | median | mean | p95 | max |
|--------|-----|--------|------|-----|-----|
| epoch_start → secure_ready | 20 | 50 | 48.9 | 58 | 59 |
| iopmp_release → IOPMP_READY | 12 | 23 | 25.6 | 45 | 47 |
| secure_ready → auth DMA req | 10 | 10 | 10 | 10 | 10 |
| secure_ready → auth commit (n=108) | 18 | 18 | 18 | 18 | 18 |

## RST-A vs RST-B

Release order does not remove the RST-A fail-open early window; it only changes when domains become legal. RST-B remains fail-closed for early unauth DMA across all schedules and random seeds in this campaign.

## Evidence levels

See `results/tables/m7_reset_evidence_levels.csv` — release-order simulation is **not** merged with M5.10 formal or Phase C directed reset evidence.
