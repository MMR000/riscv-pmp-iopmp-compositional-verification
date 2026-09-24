# Final IF01-A ledger and C.5 regression

## Final IF01-A (production IOPMP `dd7fe6…`, arbiter `20477634…`)

Source: `evidence/simulation/IF01_A_events_final.log`.

Independent write definition (from the log header):

`SRAM_WRITE := protected_memory_reset_n && sram_prot_req && sram_prot_write`

`PROT_COMMIT` is `prot_mem_changed` and is **not** a write proxy.

| Count | Value |
|-------|------:|
| CPU seed TXN_ID=1 ADDR=0x20000100 DATA=0x5151a5a5 | 1 |
| DMA_ADMITTED TXN_ID=2 AUTH=1 WDATA=0x11111111 | 1 (cyc 29) |
| ARB_DMA_GNT | 1 (cyc 32) |
| SRAM_WRITE SRC=DMA | 1 (cyc 43) |
| DUPLICATE_SRAM_WRITE | 0 |
| Harness RES | 0x600d00c1 |

Machine-readable copy: `tables/IF01_A_TRANSACTION_LEDGER.csv`.

## Final C.5 (same RTL)

Source: `evidence/simulation/c5_full_regression_anyaddr.log` and the inflight / ORD matrices.

- IF01–IF03 / STALE: suite **PASS** (no FAIL lines).
- ORD-A..H × RST-A/B: **16/16 PASS**.
- Random release-order: header says **200 seeds**. This freeze counted **200** `RAND-ORD_s*_RST-*.log` files in the source package. The suite log prints only every 25th seed. The source package has **no** `m7_realcore_release_order_random.csv`.

Approximate suite wall time: **NOT_RECORDED**.

## Historical / inconclusive (do not merge into the final row)

See `tables/HISTORICAL_FAILURES_AND_INCONCLUSIVE.csv`.

1. **Original IOPMP** `a4d977…` IF01-A: 2 DMA grants, 2 DMA SRAM writes, `DUPLICATE_SRAM_WRITE CNT=2` (`evidence/simulation/IF01_A_events_original_iopmp.log`).
2. **Production Security C.5** on IOPMP `ec77c2a9…`: 50 random seeds, PASS. Different RTL and different seed count.
3. **IF02-A** on the final IOPMP: suite PASS, but the event log contains `SCOREBOARD_FAIL` (`DUPLICATE_SRAM_WRITE` + `PAYLOAD_MISMATCH`) because CPU TXN_ID=1 is reused across reset (seed `0x5151a5a5` then `0xb0040004`). This is not a DMA re-grant.
4. **IF03-C/D** suite lines show empty `err=`. Do not invent a value.
