# Formal vs production arbiter

Compared:

| File | SHA-256 |
|------|---------|
| `m7/rtl/m7_research_arbiter.sv` | `204776349008176d2cc2934c0304a27497302cfbe522011ff9358dadf81b4519` |
| `IEEE_Access_End_to_End_Authorization_Proof_Closure/formal/configurations/stage_v2/m7_research_arbiter.v` | `4ee4c3fdcc42c536e68817b546d71975efa911b627571d3748568b4d7da3f7a5` |

Byte-identical: **NO**.

## Classification

After deleting `` `ifdef FORMAL `` regions (extra observation ports `f_state`, `f_serve_cpu`, `f_target_issued`, `f_a_addr`, `f_a_write`, `f_a_wdata` and their `assign`s) and the formal-only header comment:

**functional_body_equal_after_FORMAL_strip = True**

| Difference | Class |
|------------|--------|
| Header comment `// FORMAL-ONLY observation ports...` | FORMAL observation/instrumentation only |
| `` `ifdef FORMAL `` extra port list | FORMAL observation/instrumentation only |
| `assign f_* = ...` | FORMAL observation/instrumentation only |
| Port-list comma / `` `endif `` punctuation | syntax/build adaptation |
| `endmodule` alignment in naive line walker | **not** a functional delta (false positive of the aligner) |

**Synthesized functional difference: NONE.**

Non-FORMAL elaboration of the staged `.v` matches the production `.sv` module body (state machine, grant, `target_issued` pulse, routing). Formal tasks require the `f_*` ports; they are not in the C.5 / J2 / J3 filelists.
