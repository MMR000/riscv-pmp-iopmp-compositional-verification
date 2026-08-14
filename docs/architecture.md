# Architecture (M1)

## Block diagram

```text
                  +----------------+
                  |   CPU Master   |
                  +-------+--------+
                          |
                         PMP
                          |
                          v
                +-------------------+
                | bus_interconnect  |
                +---------+---------+
                          |
             +------------+------------+
             |                         |
             v                         v
        Normal SRAM               Protected SRAM


                  +----------------+
                  |   DMA Master   |
                  +-------+--------+
                          |
                        IOPMP
                          |
                          +--------> Interconnect
```

## Memory map

| Region          | Base         | Limit        | Size  |
|-----------------|--------------|--------------|-------|
| Normal SRAM     | 0x1000_0000  | 0x1000_FFFF  | 64 KiB |
| Protected SRAM  | 0x2000_0000  | 0x2000_FFFF  | 64 KiB |
| DMA registers   | 0x3000_0000  | 0x3000_0FFF  | 4 KiB  |
| Security config | 0x4000_0000  | 0x4000_0FFF  | 4 KiB  |

**Do not change silently.**

## PMP policy (simplified research model)

| CPU privilege | Protected SRAM |
|---------------|----------------|
| Trusted (1)   | ALLOW          |
| Untrusted (0) | DENY           |

DMA is not controlled by PMP.

## IOPMP policy (minimal region rules)

Each rule: `base`, `limit`, `requester_id`, `read_enable`, `write_enable`, `valid`.

Complete transfer `[addr, addr+length-1]` must fit a matching rule for protected-region accesses.

## Security configuration

| Offset (from 0x4000_0000) | Register        |
|---------------------------|-----------------|
| 0x0                       | PMP enable      |
| 0x4                       | IOPMP enable    |
| 0x100 + 32×N              | Rule N          |

Rule layout (+0 base, +4 limit, +8 {valid, we, re, rid}).
