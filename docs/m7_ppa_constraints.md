# M7 PPA constraints (primary comparison)

## Platform

- **Primary**: `sky130hd` (OpenROAD Flow Scripts)
- **Secondary (optional)**: `nangate45` — separate table only

## Primary clock (area comparison)

- Initial target: **10.0 ns** (same as the validated official SKY130HD Ibex flow)
- All J0–J3 area rows must use the **same** primary period on the same platform
- A 10 ns TIMING_PASS demonstrates **≥ 100 MHz** under this flow; do not report 100 MHz as Fmax

## Timing-pass criterion (Fmax sweep)

A period **P** passes iff post-route `setup WNS ≥ 0` ns with the ORFS default slack accounting for the pinned flow.

Reported demonstrated frequency:

```text
fmax_mhz_demonstrated = 1000 / P_pass  (only if timing_pass=PASS)
```

Do **not** report `1/P` when WNS is negative.

## Fmax sweep periods (ns)

```text
25, 20, 16, 12.5, 10, 8, 6.67, 5
```

Refine around the shortest passing period if needed.

## Shared physical methodology

| Variable | Value |
|----------|-------|
| Utilization target | ORFS platform default |
| Clock uncertainty | ORFS platform `config.mk` |
| IO delay model | ORFS platform default |
| Routing layers | Platform default for `sky130hd` |
| Memory policy | LOGIC-ONLY / MEMORY-BLACKBOX |
| Ibex pin | `c61e11c1e416b9ce2d996013b444c8e558d35b2b` |
| PMP regions | 8 |
| PMP granularity | 0 |

## Anti-optimization ports

Top-level retained inputs (not tied to constants):

- `cfg_*`, `dma_*` policy/transaction fields
- Domain release inputs (J3)

Live Ibex observation outputs (identical on J0–J3; required so synthesis cannot
delete the core when composition status outputs are tied off in J0/J1):

- `instr_req_o`, `instr_addr_o`
- `data_req_o`, `data_we_o`, `data_addr_o`, `data_err_o`
- `core_sleep_o`

## Evidence class

Post-route metrics from ORFS are **open-source RTL-to-GDS implementation estimates**, not silicon signoff.
