# Option A readiness architecture and J2/J3 synthesis scope

Sources: `evidence/architecture/HARDWARE_READINESS_ARCHITECTURE_DECISION.md`, `evidence/architecture/INIT_WRITER_TRUST_BOUNDARY.md`, `evidence/ppa/m7_ppa_scope.md`, `m7/ppa/rtl/m7_ppa_j2_top.sv`, `m7/ppa/rtl/m7_ppa_j3_top.sv`, `evidence/ppa/POST_REPAIR_PPA.md`, `evidence/ppa/PPA_PROVENANCE_NOTE_anyaddr.md`.

## Option A (evaluated C.5)

The C.5 top is `m7_ibex_c5_composed_top`. It does **not** instantiate `rsdg` or any other synthesizable fail-closed readiness gate.

| Signal / path | What it is | What it is not |
|---------------|------------|----------------|
| `sys_secure_ready` | Test-harness predicate | A hardware admission gate |
| IOPMP `!enable` | Fail-open (`dma_allowed = 1`) | Fail-closed refuse |
| `secure_ready` | Unused unless `RSDG_COMMIT_EPOCH` is defined | Defined in C.5 (it is not) |
| INIT-2 / `init_req` | Trusted-harness writer muxed onto the arbiter CPU port (`init_req \| cpu_adapt_req`) | Hardware-proved authority window |
| Standalone `rsdg.v` / SP-11 | Separate module-level experiment | Wired into C.5 |

Consequence: do **not** claim hardware-enforced fail-closed secure initialization for this C.5 design. Configuration completeness is an environmental / harness assumption.

Option B (synthesizable readiness gate, new named variant, full C.5 + matched PPA) was **not** implemented.

## Exact J2 / J3 synthesis scope

J2 and J3 are **not** arbiter-only netlists. They are PPA composition tops.

### J2 (`m7_ppa_j2_top`)

```
m7_ppa_top #(.PMPEnable(1'b1), .INCLUDE_COMPOSITION(1'b1), .INCLUDE_DOMAIN_RESET(1'b0))
```

Comment in the top: Ibex PMP + DMA + IOPMP + arbiter (RST-A `security_config` defaults).

Included (from `docs/m7_ppa_scope.md`):

- Ibex core (`third_party/ibex/rtl/ibex_top.sv` + dependencies)
- `m7_ibex_data_adapter.sv`
- `m7_research_arbiter.sv`
- `rtl/dma/dma_master.v`
- `rtl/iopmp/iopmp.v`
- `rtl/soc/security_config.v` (RST-A)
- Ibex `bus.sv` / `timer.sv`
- `m7_ppa_mem_slave.v` (memory shell; excluded from overhead accounting)

### J3 (`m7_ppa_j3_top`)

```
m7_ppa_top #(.PMPEnable(1'b1), .INCLUDE_COMPOSITION(1'b1), .INCLUDE_DOMAIN_RESET(1'b1))
```

Synthesize with `-DRST_B`. Adds `m7_ppa_domain_reset`.

### Explicitly excluded from J2/J3

`m7_c5_event_monitor`, `m7_target_delay`, C.5 / realcore / composed harnesses, test sync / SimCtrl, `ibex_top_tracing`, behavioral SRAM/`ram_2p` storage, Phase A/B/C/C.5 simulation tops, and `rsdg.v`.

J0/J1 isolate Ibex ± PMP and do **not** instantiate the research arbiter. They were not re-run after the arbiter repair.

## Which physical numbers attach to which RTL

| Measurement | Arbiter hash | IOPMP hash | Area (µm²) | Status |
|-------------|--------------|------------|------------|--------|
| Historical J2 | `a6046ee3…` | not separately hashed in that table | 279752 | original baseline |
| Historical J3 | `a6046ee3…` | not separately hashed | 280749 | original baseline |
| Repaired J2 | `20477634…` | **not independently recorded** in the PPA package (filelist uses `rtl/iopmp/iopmp.v` at that date; before `dd7fe6`) | 278827 | VALID_REPAIRED |
| Repaired J3 | `20477634…` | same caveat | 277934 | VALID_REPAIRED; wall 1207 s |
| After any-address IOPMP | arbiter still `20477634…` | production now `dd7fe6…` | **not re-measured** | OpenROAD not re-run |

PDK / tool: sky130hd, `CLOCK_PERIOD=20.0`, `FLOW_VARIANT=repaired_exact_once`, Docker image `openroad/orfs@sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277`. Host `openroad` binary: ABSENT.

Later notes that say “J2/J3 remain arbiter-scoped” mean: the **measured delta** after the exact-once arbiter repair is attributed to that arbiter change, and the any-address IOPMP handshake change was **not** re-characterized. They do **not** mean the synthesized hierarchy omitted IOPMP or Ibex.

The Exactly_Once table marked J2/J3 `NOT_RERUN_NO_OPENROAD`. That note is **historical**. `IEEE_Access_Production_RTL_Repair_and_Full_Ibex_Validation` later obtained repaired J2/J3 finish+GDS. Keep both records; do not flatten them into one number.
