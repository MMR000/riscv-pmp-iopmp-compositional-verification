# Reset model (M3)

## Security states

| State | Meaning |
|-------|---------|
| RUNNING | All blocks out of reset; configuration may be valid or not |
| RESET_ASSERTING | One or more block resets active |
| RESET_RECOVERY | Blocks leaving reset in arbitrary order |
| SECURE_READY | `secure_ready` asserted |

```text
secure_ready = pmp_enable && iopmp_enable && rule0_valid
```

Default after global reset (RST-A):

- `pmp_enable = 1`
- `iopmp_enable = 0` (fail-open filtering off)
- `rule0_valid = 0`

## Reset domains modeled

`formal_reset_tb.v` exposes independent deassertion for:

- CPU (`cpu_rst_n`) — tied inactive in baseline reset TB
- DMA (`dma_rst_n`)
- IOPMP (`iopmp_rst_n`)
- Security config (`sec_rst_n`)
- Interconnect (`ic_rst_n`)

Protected SRAM uses global `rst_n` only.

## RST-A vs RST-B

| Config | Reset defaults | Intent |
|--------|----------------|--------|
| **RST-A** | IOPMP disabled (`iopmp_enable=0`) | Experimental fail-open comparison |
| **RST-B** | IOPMP enabled but `rule0_valid=0` | Fail-closed rule invalid → in-region deny |

## Required ordering hypothesis (to test)

> Isolation may require `secure_ready` before DMA traffic is accepted.

Formal task `sp08_reset` explores RST-A; counterexamples are preserved as evidence, not mitigations.

## Experiments R1–R10

See `results/tables/m3_reset_matrix.csv`. Primary focus: **R10** (DMA active before IOPMP secure init).
