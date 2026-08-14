# M5.6 architecture — after repair

```
Requester                    rv_iopmp_data_abstractor_axi (proper)     axi_demux
-----------                  ------------------------------------      ---------
AW ────────────────────────► aw_valid in HANDSHAKE, phase 1 ──► AW select=route_select_q (latched)
W  ────────────────────────► w_valid in HANDSHAKE, phase 2 ──► W only after AW ready + allow
                               (after write_aw_done_q)              route_select_q from current AW
                               WAIT_B until b_valid ──────────► clears route before IDLE
Matching ◄── same ──────────► route_select_q ← allow @ valid_i
```

**Repair:** W forwarding bound to current AW authorization; route cleared after B.
