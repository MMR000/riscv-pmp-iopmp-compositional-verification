# ChatGPT Manuscript Handoff (M6)

**Do not invent results not present in this handoff.**

---

## 1. Paper working title

Compositional Verification of PMP--IOPMP Isolation in RISC-V SoCs: Reset Ordering, Initialization, and Transaction Invariants *(provisional)*

---

## 2. Central research question

Does local PMP/IOPMP access-control correctness compose into an end-to-end protected-memory isolation guarantee under reset, initialization, requester identity, and transaction-admission semantics?

---

## 3. Supported scientific statement (scoped)

"Compositional PMP–IOPMP isolation depends not only on local access-control correctness, but also on initialization, reset ordering, requester identity, and transaction-admission invariants."

Valid only within: modeled architecture, defined properties, documented assumptions, evaluated formal/simulation scope. **Not all RISC-V systems.**

---

## 4. Architecture summary

- Abstract CPU master → PMP → interconnect → protected SRAM
- DMA master → IOPMP-style mediator → interconnect
- `security_config` exports `secure_ready = pmp_enable && iopmp_enable && rule0_valid`
- **Not Ibex.** Not a complete core.

---

## 5. Threat model

- Baseline formal assumes trusted config (FA-01: no cfg_write during proofs)
- Authentic requester ID (FA-02) unless experiment models corruption
- Single clock (FA-07), no bypass (FA-06)

---

## 6. Formal assumptions (important IDs)

| ID | Meaning |
|----|---------|
| FA-01 | Trusted configuration / !cfg_write |
| FA-02 | Authentic DMA requester ID |
| FA-03 | Deterministic decode |
| FA-04 | Stable admission metadata |
| FA-05 | Model A revocation (latched at admission) |
| FA-06 | No interconnect bypass |
| FA-07 | Single clock |
| FA-08 | No spontaneous memory change |
| M59-FA-01..12 | AXI environment ladder for full-RTL M57-FP-04 |

Full: `docs/formal_assumptions.md`, `docs/m59_formal_assumptions.md`

---

## 7. Security properties (paper-relevant)

| ID | Statement |
|----|-----------|
| SP-02 | Unauthorized CPU writes blocked from protected memory |
| SP-04 | Unauthorized DMA writes blocked |
| SP-06 | Requester identity in decision (simulation) |
| SP-08 | Reset safety |
| SP-08-RST-A | Fail-open reset variant |
| SP-08-RST-B | Fail-closed reset variant |
| M57-FP-04 | Master W beat bound to authorized transaction context |

---

## 8. Final guarantee table (key rows)

| Property | Sim | BMC | PDR raw | Scientific status |
|----------|-----|-----|---------|-------------------|
| SP-02 | PASS | FORMAL_PROOF | FORMAL_PROOF | FORMAL_PROOF |
| SP-04 | PASS | FORMAL_PROOF | FORMAL_PROOF | FORMAL_PROOF |
| SP-08-RST-A | COUNTEREXAMPLE | RESET_ASSUMPTION_DEPENDENCY | NOT_RUN | RESET_ASSUMPTION_DEPENDENCY |
| SP-08-RST-B | PASS | FORMAL_PROOF | FORMAL_PROOF | FORMAL_PROOF |
| M57-FP-04-FIX2 | BOUNDED_PASS | BOUNDED_PASS | **FAIL** | **BOUNDED_EVIDENCE** |

Full CSV: `results/tables/m510_guarantee_matrix.csv`

---

## 9. RST-A result

- **Result:** DMA can affect protected memory before `secure_ready` (CE BMC step 1)
- **Classification:** RESET_ASSUMPTION_DEPENDENCY
- **NOT a vulnerability claim**
- **Evidence:** `results/formal/counterexamples/SP-08/`, `docs/m510_reset_model_comparison.md`

---

## 10. RST-B result

- **Result:** Unsafe early protected DMA commit unreachable
- **Proof method:** k-induction (SymbiYosys smtbmc z3) — "Temporal induction successful" in `results/formal/sp08_rstb_prove/logfile.txt`
- **Classification:** FORMAL_PROOF
- **Evidence:** `results/formal/sp08_rstb_prove/`

---

## 11. Requester-ID evidence

- SP-06: simulation PASS (`results/tables/security_matrix.csv` M2-RID-*)
- No standalone formal proof row for SP-06 in m510 matrix

---

## 12. Transaction-admission / outstanding-transaction evidence

- SP-09: simulation PASS (policy transition tests in security_matrix)
- SP-11: FORMAL_HARNESS_BUG (PREUNSAT) — do not cite as proof
- M57-FP-04: write-binding on full-RTL AXI path

---

## 13. M57-FP-04 status

| Channel | FIX-2 proper |
|---------|--------------|
| Verilator directed | BOUNDED_PASS |
| BMC ENV-4 | BOUNDED_PASS (primary property) |
| PDR raw | **FAIL** |
| Scientific | **BOUNDED_EVIDENCE** |

M5.8 FIX-2 CE: **HARNESS_ARTIFACT (anyinit)** — closed M5.9. **Not a genuine RTL defect.**

---

## 14. Assumption sensitivity

`results/tables/m510_assumption_sensitivity.csv` — RST-A default, M59-FA-11 master quiescence, FA-01 cfg_write, etc.

---

## 15. Formal harness / tool limitations

- SP-11 PREUNSAT → FORMAL_HARNESS_BUG
- Yices unavailable → TOOLCHAIN_LIMITATION (PDR witness replay)
- M5.8 anyinit CE → HARNESS_ARTIFACT

---

## 16. Implementation limitations

See `results/m6/limitations.md`: abstract CPU, no FPGA/ASIC, research IOPMP, no PPA data.

---

## 17. Candidate contributions (PROVISIONAL)

C1 Compositional model | C2 Reproducible workflow | C3 RST-A/B characterization | C4 Assumption sensitivity

---

## 18. Claims-to-evidence matrix

`results/m6/claims_evidence.csv` — CL-01 through CL-06

---

## 19. Reproduction commands

```bash
make m510-matrix
make m510
make paper
```

---

## 20. Tool versions

Yosys 0.68+ (read_slang), SymbiYosys, Z3 5.0.0, Verilator 5.050. Yices: not installed.

---

## 21. Git provenance

- M5.10 checkpoint: `681b2bd` (tag `checkpoint-m510-complete`)
- M6 branch: `m6-publication-freeze`
- M5.9 preserve: `results/m510/preserve/` (frozen)

---

## 22. Available figures

- `paper/figures/architecture.tex`
- `paper/figures/reset_ordering.tex`
- `paper/figures/verification_workflow.tex`

---

## 23. Available paper tables

Auto-generated: `paper/tables/property_summary.tex`, `reset_comparison.tex`, `assumption_sensitivity.tex`, `claims_evidence.tex`

---

## 24. Existing literature resources

- `riscv_key_isolation_literature_usage_guide.md`
- `results/m6/nearest_work_candidates.csv` (candidates only — verify before citing)

---

## 25. Open questions before final manuscript

- Verified related-work bibliography
- Whether SP-09 warrants formal reproduction
- SP-11 harness repair (out of M6 scope)
- Venue template selection

---

## 26. Exact files to rely on

- `results/tables/m510_guarantee_matrix.csv`
- `results/tables/m510_property_matrix.csv`
- `results/tables/m510_assumption_sensitivity.csv`
- `results/m510/m510_summary.md`
- `docs/m510_reset_model_comparison.md`
- `docs/m510_inconclusive_closure.md`
- `results/m6/claims_evidence.csv`
- `results/m6/limitations.md`

**Do not invent results not present in this handoff.**
