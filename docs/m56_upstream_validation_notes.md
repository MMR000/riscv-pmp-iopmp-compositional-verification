# M5.6 upstream validation notes (draft — do not publish)

## Affected commit

`a029581351aaf8a71831916aa8877895364e6e98` (zero-day-labs/riscv-iopmp)

## Source location

`rtl/interfaces/axi_support/rv_iopmp_data_abstractor_axi.sv` — W channel forwarding (original line ~129)

## Reproducer

```
install_policy(NSAID=0)
authorized write NSAID=0 @ 0x2000_0000
unauthorized write NSAID=1 @ 0x2000_0000
```

Evidence: `results/m55/baseline/M55-WRITE-CE-BASELINE.txt`

## Before result

- Matching: `allow=0` for unauthorized write
- Observed: BRESP OKAY, initiator W, memory modified

## After repair (proper overlay)

- Unauthorized write: SLVERR, no dst AW/W, no memory change
- R3 sequence: PASS (`results/tables/m56_write_regression.csv`)

## Repair summary

Bind W forwarding to latched AW authorization; phased AW-then-W handshake; WAIT_B for route cleanup.

## Remaining uncertainties

- Full multi-beat burst stress not exhaustively proven
- Formal proofs on abstract model only
- No FPGA/CPU integration validation
- Performance impact measured in cycle counts only (no PPA)
