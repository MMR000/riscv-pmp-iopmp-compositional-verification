# M5.6 AXI write-path transaction-binding repair

## Upstream pin

- Repository: zero-day-labs/riscv-iopmp
- Commit: `a029581351aaf8a71831916aa8877895364e6e98`

## Patch

- Path: `patches/iopmp/m56_write_path_transaction_binding.patch`
- Overlay copies: `m56/rtl/{original,naive,proper}/rv_iopmp_data_abstractor_axi.sv`
- Apply: `IOPMP_FIX=proper scripts/m56/apply_fix.sh`
- Revert: `scripts/m56/revert_fix.sh`

## Modified file

- `rtl/interfaces/axi_support/rv_iopmp_data_abstractor_axi.sv`

## Changes (proper repair)

1. **`route_select_q`** — latched at IOPMP decision (`valid_i`) instead of reusing stale `transaction_allowed_q` for demux select during W.
2. **Write AW/W phasing** — present AW to demux first (`write_aw_done_q`), then W after `aw_ready` so W-route FIFO matches current AW authorization.
3. **Gate W** — `w_valid` to demux only in `AXI_HANDSHAKE` for writes (after decision).
4. **`WAIT_B` state** — hold until `b_valid`/`b_ready` before returning IDLE; clears demux route state before next transaction.
5. **Read path** — unchanged from upstream (exit HANDSHAKE after `ar_ready`).

## Why naive W-gate alone failed (FIX-1)

Gating `w_valid` without AW-then-W phasing and without waiting for B left the FSM in IDLE while W was still pending, causing **B-channel timeout** on denied writes.

## Scripts

- `scripts/m56/apply_fix.sh` / `revert_fix.sh`
- `scripts/run/run_m56_build.sh`
