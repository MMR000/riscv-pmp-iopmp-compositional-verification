# M5.10 RST-A vs RST-B Formal Comparison

## Models

| | RST-A (fail-open) | RST-B (fail-closed) |
|--|-------------------|---------------------|
| `iopmp_enable` reset | 0 (bypass) | 1 (enforced) |
| `rule0_valid` reset | 0 | 0 |
| Harness | `formal_reset_tb.v` | `formal_reset_rstb_tb.v` |
| SBY task | `sp08_reset.sby` | `sp08_rstb_prove.sby` |

## Question

Can DMA reach protected memory before `secure_ready`?

## M5.10 fresh results (re-run `make m510-formal`)

| Model | BMC/PDR | Step | Result | Classification |
|-------|---------|------|--------|----------------|
| RST-A | BMC depth 32 | 1 | **COUNTEREXAMPLE** | **RESET_ASSUMPTION_DEPENDENCY** |
| RST-B | k-induction prove | — | **PASS (16 steps)** | **FORMAL_PROOF** |

## RST-A counterexample mechanism

1. DMA reset releases while `secure_ready=0`
2. Fail-open `iopmp_enable=0` bypasses IOPMP enforcement
3. Protected SRAM `prot_mem_changed` before configuration valid

**Not classified as SECURITY_FAILURE** — reset-ordering dependency under explicit fail-open assumption.

## RST-B behavior

Property: no **authorized** protected DMA commit (`dma_prot_commit`) before `secure_ready`.

Under fail-closed defaults, DMA-to-protected path **unreachable** for unauthorized commit before secure_ready.

## Simulation cross-check

M4 directed matrix (`m4_directed_reset_matrix.csv`): R-scenarios confirm same ordering dependency in simulation.

Counterexample preserved: `results/formal/counterexamples/SP-08/`

## Full-RTL write path (M57-FP-04)

Reset semantics for third-party IOPMP abstractor differ from abstract SoC harness. M5.7–M5.9 use derived `rst_n`; not a direct RST-A/B toggle on full RTL closure.

## Scientific classification

| Finding | Category |
|---------|----------|
| DMA before secure_ready under RST-A | RESET_ASSUMPTION_DEPENDENCY |
| Same behavior under RST-B | **Unreachable** (FORMAL_PROOF) |
| Claim of vulnerability | **Not supported** |
