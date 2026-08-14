# M5.9 AXI Environment Contract

## RTL flavor

Single-beat AXI4 write-only harness on `rv_iopmp_data_abstractor_axi` slave port. AW.len tied to 0; W.last required. Full burst types not exercised.

## Constraint classes

### A. Protocol-required (AXI4)

| ID | Constraint | Justification |
|----|------------|---------------|
| A-01 | AW stable until AWREADY | AXI spec |
| A-02 | W stable until WREADY | AXI spec |
| A-03 | WLAST=1 for single-beat | Harness ties len=0 |
| A-04 | No X on valids | Formal tool semantics |

### B. Implementation-interface-required

| ID | Constraint | Justification |
|----|------------|---------------|
| B-01 | No AR on write-only port | Harness + M57-FA-05 |
| B-02 | Single outstanding source write | Abstractor slave FSM |
| B-03 | IOPMP grant pulse in WAIT_IOPMP | Harness shim models RAR grant |
| B-04 | Derived reset 4 cycles | Matches Verilator harness |

### C. Platform/SoC assumptions

| ID | Constraint | Justification |
|----|------------|---------------|
| C-01 | env_allow stable during grant | Policy stable per lookup |
| C-02 | ini_aw/w_ready controllable | Downstream environment |

### D. Unnecessary / rejected

| ID | Constraint | Why rejected |
|----|------------|--------------|
| D-01 | Assume route_select correct | **Would assume the property** |
| D-02 | Assume denied writes never commit | **Would assume the property** |
| D-03 | Blackbox axi_demux | Would remove real RTL path |

## M59 environment ladder mapping

| Level | Adds |
|-------|------|
| ENV-0 | M5.8 baseline (M58-FA) |
| ENV-1 | AW/W stability while stalled |
| ENV-2 | Legal len/size/last |
| ENV-3 | W requires txn_active / write_aw_done |
| ENV-4 | Post-reset idle + master quiescence ⇒ no spurious ini_w |
| ENV-5 | IOPMP grant / env_allow stability |
