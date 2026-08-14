# M5.6 formal harness bug analysis

## Failing artifact

- File: `formal/harness/formal_m56_write_path_tb.sv`
- Task: `formal/tasks/m56_write_path.sby`
- Reported failure: F-WP-01 at **step 1** (`deny_decision |-> !dst_aw_valid`)

## Root cause classification

| Issue | Classification | Explanation |
|-------|----------------|-------------|
| `dst_aw_valid` is combinational "attempt" not handshake | **HARNESS_ABSTRACTION** | Defined as `(state==HANDSHAKE)&&aw_active&&!write_aw_done&&slv_aw_valid` without requiring `route_select`. Real RTL gates `axi_aux_req.aw_valid` separately. |
| `deny_decision = iopmp_valid && !iopmp_allow` same cycle as HANDSHAKE entry | **HARNESS_TIMING** | Abstract FSM sets `route_select<=iopmp_allow` and `state<=HANDSHAKE` simultaneously; combinational `dst_aw_valid` can be 1 when `slv_aw_valid` is 1 even for deny. |
| Assertion checks internal attempt signal | **PROPERTY_ENCODING** | M57-FP-01 should observe **initiator-port handshake** (`mst_req.aw_valid && mst_rsp.aw_ready`), not pre-ready combinational visibility. |
| Separate simplified FSM, not real RTL | **HARNESS_ABSTRACTION** | Does not include `axi_demux` W-route FIFO — cannot model stale-route defect (M5.5 mechanism). |
| Reset assertion on `!rst_n` | **RESET_ASSUMPTION** | Early-cycle `$assert(!route_select)` during reset release sampled before sequential clear. |
| Simulation PASS vs formal FAIL mismatch | **HARNESS_ABSTRACTION** | Confirms abstract model is not equivalent to tested RTL. |

## Signal values at step-1 counterexample (conceptual)

- `state`: transitions to HANDSHAKE
- `iopmp_valid`: 1, `iopmp_allow`: 0 → `deny_decision`: 1
- `slv_aw_valid`: 1, `write_aw_done`: 0 → `dst_aw_valid`: 1
- Real RTL: `axi_aux_req.aw_valid` gated; denied AW routes to error port; **initiator AW handshake should not occur**

## Conclusion

The M5.6 formal result is **not evidence about the repaired RTL**. It is a **harness/modeling artifact**. M5.7 replaces this with `formal_m57_fullrtl_write_path_tb.sv` instantiating real `rv_iopmp_data_abstractor_axi.sv` + `axi_demux` + `axi_err_slv`.

## Yosys follow-on note

Full RTL SymbiYosys elaboration additionally hit **Yosys 0.68 SystemVerilog frontend limits** on vendor packages (`axi_err_slv`, `axi_pkg` advanced syntax). M5.7 therefore uses **Verilator `--assert`** on the real RTL closure as the primary dynamic property checker, with SymbiYosys status recorded as INCONCLUSIVE where elaboration fails.
