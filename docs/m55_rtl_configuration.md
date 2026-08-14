# M5.5 RTL configuration (measured, not assumed)

Upstream: `zero-day-labs/riscv-iopmp` @ `a029581351aaf8a71831916aa8877895364e6e98`

## Wrapper parameters (`rtl_iopmp_dut_wrapper.sv`)

| Parameter | Instantiated value |
|-----------|-------------------|
| NUMBER_MDS | 16 |
| NUMBER_ENTRIES | 32 |
| NUMBER_MASTERS | 2 |
| NUMBER_PRIO_ENTRIES | (HWCFG2 runtime; default from regmap) |
| ADDR_WIDTH | 64 |
| DATA_WIDTH | 64 |
| ID_WIDTH | 4 (lint_wrapper IdWidth) |

## Derived / readable at runtime

| Field | Value | Source |
|-------|-------|--------|
| HWCFG0.enable reset | 0 | regmap reset |
| HWCFG1.sid_num | 2 | `hwcfg1_sid_num_qs = NUMBER_MASTERS` |
| HWCFG1.entry_num | 32 | parameter |
| SidWidth in matching | 8 | `ID_WIDTH` from wrapper (NSAID is 4-bit AXI sideband) |

## Harness policy (M55-WRITE-CE-BASELINE)

| Item | Value |
|------|-------|
| AUTH_NSAID | 0 |
| UNAUTH_NSAID | 1 |
| Protected address | 0x0000_0000_2000_0000 |
| SRCMD_EN for NSAID 0 | offset 0x1000, data 0x0000_0002 (MD0 @ bit 1) |
| MDCFG0 | 1 |
| ENTRY0 mode | TOR (cfg 0x13) — see draft5 note |
| ENTRY0 perms | R+W (bits [2:0]=3'b011) |

Readback after programming: `results/m55/config_dump.txt`
