# M5.6 original write-path flow

Upstream: `rv_iopmp_data_abstractor_axi.sv` @ a029581

## Signal path (write)

1. **Source AW/W** — requester port `slv_req_i.aw_*`, `slv_req_i.w_*`
2. **IDLE capture** — `aw_request_q`, address/size/burst latched
3. **VERIFICATION** — `transaction_en_o=1`, address presented to matching via `addr_o`, `sid_o`, `access_type_o`
4. **WAIT_IOPMP** — wait `valid_i`; latch `transaction_allowed_q = iopmp_allow_transaction_i & bc_allow_request`
5. **AXI_HANDSHAKE** — gate `axi_aux_req.aw_valid` only here; **`axi_aux_req.w_valid = slv_req_i.w_valid` always**
6. **axi_demux** — `slv_aw_select_i(transaction_allowed_q)`; W route FIFO updated on AW handshake
7. **Initiator** — port 1 AW/W when select=1; **error slave** port 0 when select=0
8. **Memory** — initiator W beat → `axi_simple_mem` write
9. **B response** — demux merges initiator/error B → `slv_rsp_o.b_*`

## Read path (unchanged by defect)

AR gated in HANDSHAKE; R channel always connected. No W-route FIFO involvement.

## Cycle sketches

### CASE A — authorized write (NSAID=0)

```
Cycle 0: aw_valid → IDLE→VERIFY
Cycle N: valid_i, allow=1 → HANDSHAKE
Cycle N+: aw_valid gated=1 → demux AW→initiator (select=1)
Same window: w_valid ungated → demux W→initiator (FIFO route=1)
→ mem write, B OKAY
```

### CASE B — fresh denied write (NSAID=1, no prior auth write)

```
HANDSHAKE with allow=0, select=0
AW→error slave; W may still enter demux but error path consumes
No initiator memory effect (symmetric deny)
```

### CASE C — authorized write → denied write (M5.5 CE)

```
Txn1 ALLOW: AW/W→initiator, demux W-route FIFO holds route=initiator
Txn2 DENY: AW→error (select=0) but W still `slv_req_i.w_valid`
Stale W-route FIFO from txn1 → W reaches initiator → memory modified
Matching: allow=0; physical path: write succeeds
```

### CASE D — denied write → authorized write

```
Txn1 DENY: no initiator route primed (or error route only)
Txn2 ALLOW: normal AW/W to initiator
```

## Key RTL signals

| Role | Signal |
|------|--------|
| Authorization known | `valid_i`, `iopmp_allow_transaction_i`, `transaction_allowed_q` |
| AW held | `state_q != AXI_HANDSHAKE` → `aw_valid` gated off |
| W accepted | always `slv_req_i.w_valid` (original defect) |
| Route stored | `axi_demux` W-select FIFO |
| Route select | `slv_aw_select_i` / `slv_ar_select_i` ← `transaction_allowed_q` |
| Denied B | `axi_err_slv` → SLVERR |
| Outstanding | single transaction FSM (no overlap) |
| W-before-AW | accepted at source; demux ties W route to AW order |
| Bursts | INCR/WRAP checked; harness uses len=0 |
| WLAST | passed through; harness uses single beat |
