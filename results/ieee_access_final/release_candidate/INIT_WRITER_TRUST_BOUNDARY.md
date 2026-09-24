# INIT_WRITER_TRUST_BOUNDARY

## Boundary statement

Trusted initialization writes in C.5 Option A are **outside** the Ibex PMP authorization domain. They are admitted because the harness asserts `init_req` onto the shared arbiter CPU port.

| Concern | Classification |
|---------|----------------|
| Who may issue init writes | **Trusted-harness assumption** |
| Mux priority / demux isolation | Hardware (combinational) |
| Ibex PMP on init traffic | **Does not apply** |
| Synthesizable readiness / RSDG | **Absent** (Option A) |

## What hardware guarantees

- While `init_req` is high, arbiter CPU payload equals `init_*`.
- `init_gnt`/`adapt_gnt` are mutually exclusive.
- Protected target write attributes follow arbiter capture `f_a_*` for the accepted beat.

## What hardware does **not** guarantee

- That `init_req` is only asserted in a secure window.
- That init completion is returned on `init_valid` if the harness drops `init_req` early.
- That disabled/unready systems refuse init (no fail-closed gate in Option A datapath).

## Option B (not implemented)

A hardware-gated readiness source would move INIT-2 from assumption to synthesizable obligation. See architecture note in `FINAL_PROOF_SCOPE_AND_ASSUMPTIONS.md`. **Not implemented this round.**
