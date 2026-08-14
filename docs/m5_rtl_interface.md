# M5 — RTL-IOPMP interface documentation

Target: **RTL-IOPMP** (`zero-day-labs/riscv-iopmp` @ `a029581351aaf8a71831916aa8877895364e6e98`)

Top module: `riscv_iopmp` (wrapped by `rtl_iopmp_dut_wrapper.sv` for M5).

## Ports

| Port | Direction | Role |
|------|-----------|------|
| `clk_i` | in | Clock |
| `rst_ni` | in | Async reset, active-low |
| `control_req_i` / `control_rsp_o` | AXI4 slave | Configuration (APB bridge inside) |
| `receiver_req_i` / `receiver_rsp_o` | AXI4+NSAID slave | Device/DMA ingress |
| `initiator_req_o` / `initiator_rsp_i` | AXI4 master | Forwarded transactions |
| `wsi_wire_o` | out | Wire interrupt |

## Requester identity

Per upstream README: **NSAID** (4-bit) on AW/AR channels (`lint_wrapper::req_nsaid_t`).

- Not AXI `USER` for RRID in this implementation
- Mapped to internal `sid_i` in matching logic (`rv_iopmp_data_abstractor_axi.sv`)
- M5 harness: `AUTH_NSAID=0`, `UNAUTH_NSAID=1` (valid for `NUMBER_MASTERS=2`)

## Enable control

`HWCFG0.enable` (bit 31, offset `0x8`):

- **W1SS** write-1-to-set
- **Reset value: 0** (`RESVAL=1'h0` in `rv_iopmp_regmap.sv`)
- Exported as `iopmp_enabled_o` → matching logic bypass when 0

## M5 harness parameters

```
NUMBER_MDS     = 16
NUMBER_ENTRIES = 32
NUMBER_MASTERS = 2
```

Configuration uses native register offsets from `rv_iopmp_reg_pkg`.
