# IBEX-PMP test specifications (M7 Phase A)

| test_id | purpose | PMP config | privilege | operation | address | expected | mcause (if trap) |
|---------|---------|------------|-----------|-----------|---------|----------|------------------|
| IBEX-PMP-01 | M-mode write normal SRAM | R0 16KiB NAPOT RWX @ RAM_BASE, R1 deny | M | write | 0x00101100 | ALLOW | — |
| IBEX-PMP-02 | M-mode read normal SRAM | same | M | read | 0x00101100 | ALLOW | — |
| IBEX-PMP-03 | M-mode programs PMP CSRs | CSR write (RMW pmpcfg0) | M | csr | pmpaddr/cfg | ALLOW | — |
| IBEX-PMP-04 | U-mode protected read denied | R1 no R/W/X | U | load | 0x00180100 | LOAD_FAULT | 5 |
| IBEX-PMP-05 | U-mode protected write denied | R1 no W | U | store | 0x00180100 | STORE_FAULT, mem unchanged | 7 |
| IBEX-PMP-06 | U-mode normal read allowed | R0 RWX | U | load + ecall | 0x00101100 | ALLOW | 8 (ecall success) |
| IBEX-PMP-07 | U-mode boundary protected read | R1 deny | U | load | prot_last (0x00180FFC) | LOAD_FAULT | 5 |
| IBEX-PMP-08 | M-mode PMP reconfig + write | R1 RW after reconfig | M | write | 0x00180100 | ALLOW | — |

Smepmp disabled. M-mode accesses ignore PMP unless MPRV set (standard Ibex PMP).
