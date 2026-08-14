# M5.5 read vs write path comparison

| Function | READ | WRITE | Shared? |
|----------|------|-------|---------|
| NSAID input | `ar.nsaid` | `aw.nsaid` | Same sid_o mux (aw_request_q) |
| Access type | ACCESS_READ (3'b001) | ACCESS_WRITE (3'b010) | Same matching FSM |
| Permission decode | entry_analyzer `(type & perms)==type` | same | **Shared** |
| MD / srcmd lookup | srcmd_table[sid] | same | **Shared** |
| AW/AR gate to demux | ar_valid gated to AXI_HANDSHAKE | aw_valid gated | Symmetric |
| **W beat to demux** | n/a | **w_valid always on** | **WRITE-only bug** |
| Demux route select | slv_ar_select_i(transaction_allowed_q) | slv_aw_select_i | Shared register |
| Error slave | axi_err_slv AR/R | axi_err_slv AW/W/B | Shared demux port 0 |
| Initiator | initiator AR/R | initiator AW/W/B | Port 1 |

## Security relevance

Matching logic is symmetric; observed read/write asymmetry in M5 directed suite comes from
**W-channel leakage** in `rv_iopmp_data_abstractor_axi`, not from separate permission FSMs.

## Source locations

- Data abstractor: `rtl/interfaces/axi_support/rv_iopmp_data_abstractor_axi.sv`
- Matching: `rtl/matching_logic/rv_iopmp_matching_logic.sv`
- Entry permissions: `rtl/matching_logic/rv_iopmp_entry_analyzer.sv:64`
- Demux: `vendor/axi_demux.sv` (w_select FIFO)
