# IF01_A_INDEPENDENT_REPRODUCTION

## Method

Matched builds of **original** vs **repaired** IOPMP against the same repaired arbiter (`20477634…`), independent SRAM-write monitor, `TARGET_DELAY=8`.

| Variant | IOPMP SHA-256 |
|---------|---------------|
| original | `a4d9773716d91025330cbe2e7789842c697e59d56a981fdc930cee1f260c141f` |
| repaired | `ec77c2a999e5f65e28f3eee43ed1c5b18cfc45e6c8c41b29c88f7fa1c7609485` |

## Independent counts (actual `sram_prot_req && sram_prot_write`)

| Metric | Original IOPMP | Repaired IOPMP |
|--------|----------------|----------------|
| DMA_ADMITTED | 1 (TXN_ID=2) | 1 (TXN_ID=2) |
| ARB_DMA_GNT | **2** | **1** |
| SRAM_WRITE SRC=DMA | **2** | **1** |
| Scoreboard | **DUPLICATE_SRAM_WRITE CNT=2** | clean (no SCOREBOARD_FAIL) |

Admission metadata (repaired & original): `ADDR=0x20000100 WDATA=0x11111111 WRITE=1` via IOPMP `txn_*` + requester snapshot (not post-reset zeros).

`PROT_COMMIT` lags `SRAM_WRITE` by one cycle (registered `mem_changed`) — events are distinct.

## Verdict

Independent observation **confirms** original duplicate writes and repaired exactly-once for IF01-A.
