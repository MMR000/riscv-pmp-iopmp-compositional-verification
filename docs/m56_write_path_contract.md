# M5.6 write-path repair contract

Permanent property IDs for paper cross-reference.

## WP-01 Authorization Consistency

Every downstream write transaction must correspond to an AW transaction whose IOPMP decision was ALLOW.

## WP-02 Denied Write Non-Propagation

If AW authorization is DENY: no downstream AW handshake and no downstream W handshake for that transaction.

## WP-03 Denied Write Non-Side-Effect

A denied write must not modify protected memory.

## WP-04 Write Route Freshness

The W channel of transaction N must never use route state belonging to transaction N−1.

## WP-05 AW/W Association

All W beats of an authorized AW follow the routing decision associated with that AW.

## WP-06 Denied Transaction Completion

A source-side denied write completes with SLVERR (error slave path) without indefinite hang.

## WP-07 Authorized Write Preservation

Authorized writes complete and modify intended memory.

## WP-08 Backpressure Invariance

AWREADY/WREADY/BREADY timing must not change authorization outcome.

## WP-09 Cross-Transaction Isolation

One transaction's authorization/route must not affect a later transaction with different identity/permissions.

## WP-10 Requester Binding

Write authorization uses the requester identity captured for the same AW transaction (`aw.nsaid` → `sid_o`).

## WP-11 Read Regression

Read-side deny/allow behavior unchanged by write-path repair.

## WP-12 Reset/Cleanup

Internal write-route/buffer state is empty after reset; no stale authorization survives.

## Formal property map

| Formal ID | Contract |
|-----------|----------|
| F-WP-01 | WP-02 (downstream AW) |
| F-WP-02 | WP-02 (downstream W) |
| F-WP-03 | WP-03 |
| F-WP-04 | WP-01, WP-05 |
| F-WP-05 | WP-04, WP-12 |
| F-WP-06 | WP-04 |
| F-WP-07 | WP-12 |
| F-WP-08 | WP-07 (cover) |
| F-WP-09 | WP-06 (cover) |
