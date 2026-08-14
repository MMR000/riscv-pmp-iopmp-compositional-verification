# M5.9 Formal Assumptions

| ID | Statement | Scope | Source | Protocol? | If removed |
|----|-----------|-------|--------|-----------|------------|
| M59-FA-01 | AW payload stable while stalled | Master | AXI A-01 | Yes | Illegal AW morphing |
| M59-FA-02 | W payload stable while stalled | Master | AXI A-02 | Yes | Illegal W morphing |
| M59-FA-03 | len=0, w.last=1, size≤3 | Master | Harness | Impl | Illegal beat params |
| M59-FA-04 | Derived rst_n from clk count | Harness | M5.9 | Impl | anyinit reset artifacts |
| M59-FA-05 | src_w ⇒ txn_active | Master/impl | Write binding | Impl | W before txn |
| M59-FA-06 | mem_write ⇒ write_aw_done (proper) | Initiator | FIX-2 RTL | Impl | AW/W reorder CE |
| M59-FA-07 | First post-reset cycle idle | DUT | Reset semantics | Impl | anyinit spurious W |
| M59-FA-08 | env_allow stable during grant | IOPMP env | M57-FA-08 | Platform | Policy flip CE |
| M59-FA-09 | grant in WAIT_IOPMP | IOPMP env | M57-FA-06 | Platform | Unbounded wait |
| M59-FA-10 | !txn_active when master idle | Harness | Observer consistency | Impl | anyinit txn_active |
| M59-FA-11 | !mem_write when master idle | Initiator | No master ⇒ no write | Impl | **M5.8 FIX-2 CE** |
| M59-FA-12 | M58-FA-01..06 retained | All | M5.8 | Mixed | See ladder CSV |

## Property alignment fix (M5.9)

Proper variant `w_context_ok` in FORMAL now matches Verilator: **`route_sel`**, not grant observer alone.
