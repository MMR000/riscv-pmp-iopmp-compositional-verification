# Claims-to-evidence register (M6)

## CL-01

- **claim_id**: CL-01
- **claim_text**: CPU unauthorized protected-memory writes blocked by modeled PMP under stated assumptions
- **property_id**: SP-02
- **scientific_status**: FORMAL_PROOF
- **evidence_type**: formal+simulation
- **evidence_file**: results/tables/m510_guarantee_matrix.csv
- **reproduction_command**: make m510-matrix
- **git_commit**: 681b2bd
- **limitations**: Abstract CPU; FA-03..FA-08
- **paper_section**: 07_results

## CL-02

- **claim_id**: CL-02
- **claim_text**: Unauthorized DMA protected-memory writes blocked by modeled IOPMP under stated assumptions
- **property_id**: SP-04
- **scientific_status**: FORMAL_PROOF
- **evidence_type**: formal+simulation
- **evidence_file**: results/tables/m510_guarantee_matrix.csv
- **reproduction_command**: make m510-matrix
- **git_commit**: 681b2bd
- **limitations**: Research IOPMP model; FA-02,FA-05
- **paper_section**: 07_results

## CL-03

- **claim_id**: CL-03
- **claim_text**: Fail-open reset model permits reachable early-DMA protected-memory state before secure_ready
- **property_id**: SP-08-RST-A
- **scientific_status**: RESET_ASSUMPTION_DEPENDENCY
- **evidence_type**: formal counterexample
- **evidence_file**: results/formal/counterexamples/SP-08/
- **reproduction_command**: cd formal/sby && sby -f -d ../../results/formal/sp08_reset sp08_reset.sby
- **git_commit**: 681b2bd
- **limitations**: Model-level; not a product vulnerability claim
- **paper_section**: 07_results

## CL-04

- **claim_id**: CL-04
- **claim_text**: Fail-closed reset model excludes corresponding unsafe state under formal model and assumptions
- **property_id**: SP-08-RST-B
- **scientific_status**: FORMAL_PROOF
- **evidence_type**: k-induction (SymbiYosys smtbmc z3)
- **evidence_file**: results/formal/sp08_rstb_prove/logfile.txt
- **reproduction_command**: make m510-formal
- **git_commit**: 681b2bd
- **limitations**: RST-B defaults; FA-01,FA-07
- **paper_section**: 07_results

## CL-05

- **claim_id**: CL-05
- **claim_text**: Requester identity participates in access-control decisions
- **property_id**: SP-06
- **scientific_status**: PASS (simulation)
- **evidence_type**: directed simulation
- **evidence_file**: results/tables/security_matrix.csv
- **reproduction_command**: make m2
- **git_commit**: 681b2bd
- **limitations**: Simulation only for SP-06; FA-02
- **paper_section**: 07_results

## CL-06

- **claim_id**: CL-06
- **claim_text**: M57-FP-04 write-binding on repaired RTL has bounded evidence, not unbounded proof
- **property_id**: M57-FP-04-FIX2
- **scientific_status**: BOUNDED_EVIDENCE
- **evidence_type**: Verilator+BMC ENV-4; PDR raw FAIL
- **evidence_file**: results/tables/m510_guarantee_matrix.csv
- **reproduction_command**: make m59-bmc
- **git_commit**: 681b2bd
- **limitations**: M59-FA-01..12; PDR not proved; M5.8 CE was harness artifact
- **paper_section**: 07_results
