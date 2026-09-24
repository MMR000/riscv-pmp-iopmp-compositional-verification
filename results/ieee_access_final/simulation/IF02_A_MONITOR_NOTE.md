# IF02-A SCOREBOARD_FAIL classification

## Verdict

**Monitor / ledger reset-epoch defect. Not an RTL defect.**

Historical log (`historical/IF02-A_RST-B.historical.log`):

- TXN_ID=1 seed write `0x5151a5a5` completes (cyc 18).
- CPU reset (cyc 123) while a later firmware store is in flight.
- DELAY_ACCEPTED still bound to TXN_ID=1.
- SRAM write `0xb0040004` attributed to TXN_ID=1 → `DUPLICATE_SRAM_WRITE` + `PAYLOAD_MISMATCH`.
- Suite scorer ignored SCOREBOARD_FAIL and reported PASS.

Two different payloads on the same TXN_ID is a ledger reuse bug: `last_cpu_id` / `last_delay_id` survived after the seed write committed.

RTL: seed write + one Model-A drain of `0xb0040004` after reset. Not a second grant of the same admission.

## Monitor-only fix

`m7/rtl/m7_c5_event_monitor.sv` (SHA-256 `cfaa2ea2434a3aa4d3e7cd4a0c2ebf3237fed61bb3edbf06bdc8dcd68c221636`):

- Close last-CPU/last-delay pointers on CPU reset when that TXN already has `write_cnt>=1`.
- Allocate a new TXN_ID on DELAY_ACCEPTED if the previous CPU TXN is already written.
- Do not increment a closed TXN; late-bind a new row instead.
- Suite `classify_if02` now FAILs if `SCOREBOARD_FAIL` is present.

## Rerun (RST-B, rebuilt C.5)

`tests/IF02-A_RST-B.log`:

- TXN_ID=1 seed `0x5151a5a5` (cyc 18)
- `LEDGER_CPU_EPOCH epoch=1` (cyc 123)
- TXN_ID=2 `0xb0040004` (cyc 134)
- `SCOREBOARD_FAIL` count = 0
- Suite: PASS `sb_fail=0`

IF01-A after the same rebuild: 1 DMA admit / 1 grant / 1 SRAM write, `sb_fail=0`.
