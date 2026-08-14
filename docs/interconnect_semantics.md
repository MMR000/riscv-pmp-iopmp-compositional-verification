# Interconnect semantics (M2)

## Module

`bus_interconnect` — fixed-decode, single-transaction arbiter.

## Arbitration policy

**Fixed CPU priority.** When both CPU and DMA present a request while the arbiter is idle, the CPU transaction is selected first. DMA is served only when no CPU request is pending at selection time.

This is deterministic, not round-robin.

## Request acceptance

- One transaction is active at a time (0 or 1 outstanding at the interconnect).
- On the cycle the arbiter leaves `ARB_IDLE`, address/write/data of the selected master are latched into `active_*` registers.
- The selected master receives `gnt` when the downstream SRAM accepts the beat.

## Response timing

- SRAM is combinational grant + single-cycle valid (request accepted and response valid same cycle when `req` is asserted).
- Interconnect returns to `ARB_IDLE` after the active beat completes.

## Concurrent masters

Both masters may assert `start` in the same testbench cycle. Each master FSM will assert `req` on the next cycle. If both `req` signals are high when the arbiter is idle, **CPU wins**.

There is no interleaving of beats from two masters.

## In-flight transactions

At the interconnect layer: **at most one beat in flight**.

The IOPMP adds a separate admission/commit pipeline (see `docs/decisions.md`); end-to-end outstanding behavior is bounded by that pipeline plus interconnect serialization.

## Unmapped addresses

Transactions to unmapped addresses complete with read data zero and no memory side effect.
