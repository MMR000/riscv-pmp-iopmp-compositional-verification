# Threat model (initial)

## Assets

- Protected SRAM (`0x2000_0000` – `0x2000_FFFF`)
- Security configuration registers
- Normal SRAM (non-security-critical in M1)

## Adversaries

- Untrusted CPU software (unprivileged context)
- Unauthorized DMA master (wrong requester ID or no matching IOPMP rule)
- Authorized DMA master (in-scope for positive tests only in M1)

## Trust assumptions (M1)

- PMP correctly mediates CPU accesses when enabled
- IOPMP correctly mediates DMA accesses when enabled
- Interconnect routes only admitted transactions
- Testbench is trusted observability

## Out of scope (M1)

- Physical attacks, fault injection, debug ports
- Full RISC-V specification compliance
- OS-level software stack
