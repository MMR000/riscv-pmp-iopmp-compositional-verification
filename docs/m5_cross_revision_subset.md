# M5 — REF ↔ RTL cross-revision comparable subset

Official REF: **v0.8.2** | RTL: **v1.0.0-draft5**

## Comparable scenarios (aligned 4-byte transactions)

| ID | Scenario | Comparable? |
|----|----------|-------------|
| S1 | Pre-config protected write with checking **disabled/bypassed** | Yes (REF enable=0 ≈ RTL reset default) |
| S2 | Pre-config protected write with checking **enabled**, no entry | Yes (REF enable=1 ≈ RTL after W1SS enable) |
| S3 | Authorized write post-policy | Yes (different SRCMD encoding) |
| S4 | Unauthorized requester | Partial (NSAID vs RRID table indexing) |
| S5 | No matching entry | Yes |
| S7 | Post-reset pre-config write | Yes (both return bypass-class behavior) |

## Excluded from REF↔RTL diff

- MD/SRCMD table format differences beyond minimal policy
- WSI / MSI / stall-buffer optional features
- Unaligned NA4 (REF-only strictness documented in M5A)

## SRCMD encoding note

RTL `SRCMD_EN.md[j]` occupies register bit **j+1** (bit 0 is lock). MD0 enable = `0x02`, not `0x01`.
