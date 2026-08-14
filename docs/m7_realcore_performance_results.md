# M7 real-core performance results (Phase D.2)

## Method

Cycle-level metrics from Verilator simulation. **Not** derived from OpenROAD wall time or requested clock.

| Class | Source | Landmarks |
|-------|--------|-----------|
| CPU auth/deny | Phase A Ibex simple_system + PMP firmware (`PERF-CPU-0*.elf`) | `mcycle` / `cycle` CSR before access and in trap handler |
| DMA directed | C.5 event log (`m7_c5_events.log`) | `DMA_ADMITTED` / `PROT_COMMIT` / `DMA_COMPLETED` |
| DMA throughput | C.5 harness `C5_TEST=900` + `DMA_N` | first `dma_start` cycle → last `dma_done` |
| DMA 500-seed | C.5 ORD path `C5_TEST=200` | admit→ERR=0 and deny→ERR=1 separately |

Do **not** reuse the C.5 ORD harness for U-mode CPU fault latency; PERF-CPU-03/04 use Phase A PMP firmware.

## Directed CPU (Phase A mcycle)

| Test | Metric | Cycles | Notes |
|------|--------|-------:|-------|
| PERF-CPU-01 | mcycle before→after authorized protected load | 5 | M-mode |
| PERF-CPU-02 | mcycle before→after authorized protected store | 5 | M-mode |
| PERF-CPU-03 | U-mode attempt→trap | 28 | mcause=5 load fault |
| PERF-CPU-04 | U-mode attempt→trap | 30 | mcause=7 store fault |

Landmark detail for deny path: U-mode `csrr cycle` → store into `g_cyc_req` → faulting load/store; trap handler `csrr mcycle`. Delta includes the CSR/store prologue before the faulting access.

Frozen IBEX-PMP-01..08 matrix hash unchanged (`a6176844…`).

## Directed DMA endpoints (do not collapse)

| Test | Endpoint | Cycles | Interpretation |
|------|----------|-------:|----------------|
| PERF-DMA-01a | admit → **first** `PROT_COMMIT` | 5 | first memory-write visibility |
| PERF-DMA-01b | admit → **last** `PROT_COMMIT` strobe | 9 | previous directed “commit=9”; monitor holds `mem_changed` for several cycles |
| PERF-DMA-02 | admit → first `DMA_COMPLETED ERR=0` | 7 | response/completion |
| PERF-DMA-03 | deny → first `DMA_COMPLETED ERR=1` | 0 | same-cycle deny+complete in this monitor |

**Why directed commit=9 while random campaign reports 7:** they measure different endpoints. Random/median uses admit→`DMA_COMPLETED ERR=0` (=7). The older directed “9” is admit→last `PROT_COMMIT` strobe, not completion.

## Measured sequential DMA throughput

Single-outstanding allowed writes (`C5_TEST=900`). Includes harness arm/wait gaps between transfers.

| N | first_req | last_done | total_cycles | cycles/transfer | transfers/cycle | class |
|--:|----------:|----------:|-------------:|----------------:|----------------:|-------|
| 16 | (see CSV) | (see CSV) | 236 | 14.75 | 0.067797 | MEASURED |
| 64 | | | 956 | 14.9375 | 0.066946 | MEASURED |
| 256 | | | 3836 | 14.9844 | 0.066736 | MEASURED |

Raw: `results/tables/m7_dma_throughput.csv`. These are **not** DERIVED from 7×N.

## 500-seed distributions (separate classes)

| Class | n | min | median | mean | p95 | max |
|-------|--:|----:|-------:|-----:|----:|----:|
| authorized DMA admit→complete ERR=0 | 500 | 7 | 7 | 7 | 7 | 7 |
| denied DMA deny→complete ERR=1 | 500 | 0 | 0 | 0 | 0 | 0 |

Raw: `results/m7/performance/raw_samples.csv`.

## Limitations

- Outstanding depth = 1 on the research DMA path
- Denied DMA response latency 0 means monitor reports deny and complete in the same cycle
- CPU deny deltas include U-mode prologue before the faulting access
- Concurrent CPU+DMA attribution not isolated in this pass
