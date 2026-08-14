# M5.6 architecture — before repair

```
Requester                    rv_iopmp_data_abstractor_axi              axi_demux
-----------                  -----------------------------              ---------
AW ────────────────────────► aw_valid GATED (HANDSHAKE only) ──► AW select=transaction_allowed_q
W  ────────────────────────► w_valid ALWAYS ON ──────────────► W route FIFO (stale risk)
                                                                    ├─► [0] error slave
                                                                    └─► [1] initiator → memory
Matching ◄── transaction_en ── FSM: IDLE→VERIFY→WAIT→HANDSHAKE
         ──► allow ──────────► transaction_allowed_q
```

**Defect:** W beats can enter demux before/during AW denial and reuse prior W-route token.
