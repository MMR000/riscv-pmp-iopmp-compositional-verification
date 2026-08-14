# M5.5 NSAID → RRID trace

Upstream commit: `a029581351aaf8a71831916aa8877895364e6e98`

## READ path

```
receiver_req_i.ar.nsaid (4b)
  → rv_iopmp_data_abstractor_axi.slv_req_i.ar.nsaid
  → sid_o = ar.nsaid when aw_request_q=0  (rv_iopmp_data_abstractor_axi:106)
  → riscv_iopmp.sid
  → rv_iopmp_matching_logic.sid_i
  → srcmd_en = {srcmd_table_i[sid_i].enh, srcmd_table_i[sid_i].en.md} in IDLE (matching:126)
  → has_md / MD walk (matching:310-320)
  → entry read + rv_iopmp_entry_analyzer (access_type_q = ACCESS_READ)
  → allow_transaction_o / ERROR
  → transaction_allowed_q → axi_demux.slv_ar_select_i
  → initiator_req_o.ar_valid OR axi_err_slv
```

## WRITE path

```
receiver_req_i.aw.nsaid (4b)
  → sid_o = aw.nsaid when aw_request_q=1  (data_abstractor:106)
  → (same matching path with access_type_q = ACCESS_WRITE)
  → transaction_allowed_q → axi_demux.slv_aw_select_i
  → initiator_req_o.aw_valid (gated to AXI_HANDSHAKE only, line 113)
  → **BUG**: initiator_req_o.w_valid NOT gated (line 129) — W enters demux during VERIFICATION
  → axi_demux routes W using w_select FIFO from prior AW
```

## Key signals (baseline unauthorized write after auth write)

| Signal | Unauthorized WRITE | Unauthorized READ |
|--------|-------------------|-------------------|
| aw/ar nsaid at receiver | AW=1 | AR=1 |
| sid at valid | 0 (sampled) | 1 |
| has_md | 0 | 0 |
| allow_transaction | 0 | 0 |
| initiator AW/AR | 0 | 0 |
| initiator W | **1** | n/a |
| memory effect | **modified** | none |

## RRID note

With `NUMBER_MASTERS=2`, RTL indexes `srcmd_table[sid]` directly. NSAID is treated as SID/RRID
index for masters 0..1. NSAID≥2 accesses out-of-range table index (implementation hazard).
