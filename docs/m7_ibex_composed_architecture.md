# M7 Ibex composed architecture (Phase B)

## Research question

Does **real Ibex architectural PMP** + **independent DMA** + **IOPMP-style mediation** +
**shared protected SRAM** compose into the expected CPU/DMA isolation behavior?

## Block diagram

```
                    +------------------+
                    |    Real Ibex     |
                    | PMPEnable = 1    |
                    | (internal PMP)   |
                    +--------+---------+
                             |
                    post-PMP data bus
                             |
              +--------------+---------------+
              |                              |
              v                              v
     Ibex local bus                 m7_ibex_data_adapter
     (boot RAM / sim /             (word research bus)
      timer / test sync)                     |
                                             v
                                   m7_research_arbiter
                                      /             \
                                     v               v
                              normal SRAM      protected SRAM
                              0x1000_0000      0x2000_0000
                                                     ^
                                                     |
                                               +-----+-----+
                                               |   IOPMP   |
                                               +-----+-----+
                                                     ^
                                                     |
                                                 dma_master
```

`m7_research_arbiter` is Ibex-friendly (grant-on-accept) and is **separate** from
the historical `rtl/interconnect/interconnect.v` used by M1–M5, so prior
reproduction is preserved.

## CPU protection path

Ibex → **internal architectural PMP** → Ibex `data_*` interface →
local decode / `m7_ibex_data_adapter` → `m7_research_arbiter` → shared SRAM.

There is **no** project research `pmp.v` on the Ibex path.

## DMA protection path

`dma_master` → research `iopmp` → same `m7_research_arbiter` → **same** protected SRAM.

DMA never enters Ibex PMP.

## Trusted configuration

IOPMP rule programming is performed by `m7_composed_harness` via direct
`security_config` sideband writes.

**Classification: TRUSTED_CONFIGURATION** (testbench/harness), not firmware MMIO.

Firmware configures only Ibex PMP CSRs in M-mode.

## Memory map

| Region | Address |
|--------|---------|
| Ibex boot/code RAM | `0x0010_0000` (1 MiB) |
| SimCtrl | `0x0002_0000` |
| Timer | `0x0003_0000` |
| Normal shared SRAM | `0x1000_0000`–`0x1000_FFFF` |
| Protected shared SRAM | `0x2000_0000`–`0x2000_FFFF` |
| DMA regs (map reserved) | `0x3000_0000` |
| Security cfg (harness) | `0x4000_0000` |
| Test sync mailbox | `0x5000_0000` |

Test word: protected `0x2000_0100`.

Requester IDs: AUTH=`0x01`, UNAUTH=`0x02`.

## Adapter semantics

`m7_ibex_data_adapter` bridges Ibex LSU (`req/gnt/rvalid/we/be/addr/wdata/rdata/err`)
to the research word bus (`req/addr/write/wdata/gnt/valid/rdata`).

- Byte enables are accepted from Ibex but the research SRAM is word-oriented.
- PMP denials remain inside Ibex (no external data request for PMP-denied accesses).
- Bus errors are not used to emulate PMP faults (`data_err` forced 0 on research path).

## Synchronization

Mailbox at `0x5000_0000`:

| Offset | Name | Role |
|--------|------|------|
| 0x00 | TEST_READY | CPU writes phase number |
| 0x04 | GO | Harness sets when ready |
| 0x14 | HRESULT | Harness DMA result (`0xDEAD0001` deny / `0x600D0001` allow) |

For concurrent tests (COMP-06..08), harness starts DMA before asserting GO so
CPU `sim_halt` cannot cut off DMA issuance.
