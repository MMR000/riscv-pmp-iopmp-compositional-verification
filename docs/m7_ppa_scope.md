# M7 PPA synthesis scope

## Included modules (J0–J3)

| Module | Path | Variants |
|--------|------|----------|
| PPA tops | `m7/ppa/rtl/m7_ppa_j{0,1,2,3}_top.sv` | J0–J3 |
| PPA core | `m7/ppa/rtl/m7_ppa_top.sv` | all |
| Mem shell | `m7/ppa/rtl/m7_ppa_mem_slave.v` | all (excluded from overhead) |
| Domain reset | `m7/ppa/rtl/m7_ppa_domain_reset.v` | J3 |
| Ibex core | `third_party/ibex/rtl/ibex_top.sv` + dependencies | all |
| Data adapter | `m7/rtl/m7_ibex_data_adapter.sv` | J2, J3 |
| Arbiter | `m7/rtl/m7_research_arbiter.sv` | J2, J3 |
| DMA | `rtl/dma/dma_master.v` | J2, J3 |
| IOPMP | `rtl/iopmp/iopmp.v` | J2, J3 |
| Security config | `rtl/soc/security_config.v` | J2 (RST-A), J3 (`-DRST_B`) |
| Bus / timer | Ibex `bus.sv`, `timer.sv` | all |

## Explicitly excluded (not synthesized)

| Module | Reason |
|--------|--------|
| `m7_c5_event_monitor` | C.5 simulation instrumentation |
| `m7_target_delay` | C.5 test-only delay |
| `m7_c5_harness`, `m7_realcore_reset_harness`, `m7_composed_harness` | Test sequencers |
| `m7_test_sync`, `m7_reset_test_sync` | Test mailbox |
| `simulator_ctrl` | SimCtrl / `$finish` |
| `ibex_top_tracing` | Trace-only wrapper |
| Behavioral `sram` / `ram_2p` storage | Memory-blackbox policy |
| Phase A/B/C/C.5 simulation tops | Frozen functional evidence only |

## J4 status

**NOT_APPLICABLE_TO_REALCORE_TOP**

Production FIX-2 transaction binding applies to the independent AXI IOPMP abstractor (`rv_iopmp_data_abstractor_axi`), not the research `iopmp.v` on the real-Ibex composed path. Measured separately as **I0/I1**.

## Variant definitions

- **J0**: `PMPEnable=0`, no composition
- **J1**: `PMPEnable=1`, no composition → isolates architectural PMP (`J1−J0`)
- **J2**: J1 + DMA + IOPMP + arbiter + adapter (RST-A) → `J2−J1`
- **J3**: J2 + `RST_B` security_config + `m7_ppa_domain_reset` → `J3−J2`

Functional Phase A/B/C/C.5 tops are **not modified**.
