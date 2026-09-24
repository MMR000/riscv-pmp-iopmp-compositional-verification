# IF01-A final result

**Current status: RESOLVED / PASS** (`SIMULATION_EVIDENCE`).

RTL: IOPMP `dd7fe6a89f22a9c830615528733b2d51ccfb852ca0966d3991ab1172d06c82c8`, arbiter `204776349008176d2cc2934c0304a27497302cfbe522011ff9358dadf81b4519`.

Independent write event: `SRAM_WRITE := protected_memory_reset_n && sram_prot_req && sram_prot_write`.  
`PROT_COMMIT` / `mem_changed` is **not** a write proxy.

| Count | Value |
|------:|-------|
| Unique DMA admissions | 1 (cyc 29, TXN_ID=2) |
| Arbiter DMA grants | 1 (cyc 32) |
| Actual DMA protected-SRAM writes | 1 (cyc 43) |
| Harness result | `0x600d00c1` |
| `DUPLICATE_SRAM_WRITE` | 0 |

Sources:

- `results/tables/m7_if01_a_final_ledger.csv`
- `results/ieee_access_final/release_candidate/IF01_A_events_final.log`
- `results/ieee_access_final/release_candidate/IF01_A_TRANSACTION_LEDGER.csv`

Historical INCONCLUSIVE: `docs/history/IF01_A_HISTORICAL_INCONCLUSIVE.md`.

Historical original IOPMP `a4d977…` negative control: 1 admission, 2 grants, 2 actual DMA SRAM writes, `DUPLICATE_SRAM_WRITE CNT=2` — `results/ieee_access_final/release_candidate/IF01_A_events_original_iopmp.log`.
