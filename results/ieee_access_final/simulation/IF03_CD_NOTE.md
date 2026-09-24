# IF03-C/D empty err= field

## Cause

Parser only accepted `EARLY ERR=(\d+)`.

- IF03-C (`C5_TEST=122`): IC held down; harness printed `EARLY_ISSUE_TIMEOUT` and never `EARLY ERR=`. DMA not issued.
- IF03-D (`C5_TEST=123`): printed `IF_OUTCOME ... ERR=0` but no `EARLY ERR=` line.

## Fix (reporting + harness print; test intent unchanged)

- Harness: `EARLY ERR=NOT_ISSUED ... REASON=IC_DOWN` on IF03-C timeout.
- Harness: `EARLY ERR=%0d ... REASON=SEC_RESET_NO_DMA_ISSUE` on IF03-D outcome.
- Parser: accept `NOT_ISSUED`, `EARLY_ISSUE_TIMEOUT`, and `IF_OUTCOME ERR=`.

## Rerun

| Test | err= | peek | result |
|------|------|------|--------|
| IF03-C RST-B | NOT_ISSUED | 0x5151A5A5 | PASS (IC down, DMA not issued) |
| IF03-D RST-B | 0 | 0x5151A5A5 | PASS (sec reset, no DMA issue) |

Historical logs preserved under `historical/`.
