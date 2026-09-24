# Option A — evaluated C.5 architecture

Copied from the release-candidate architecture decision. Do not strengthen.

The evaluated C.5 top (`m7_ibex_c5_composed_top`) does **not** instantiate `rsdg` or any equivalent synthesizable fail-closed readiness gate.

- `sys_secure_ready` is a **harness observation / scheduling predicate**.
- Trusted initialization comes from `m7_c5_harness` `ST_SEED`.
- INIT authority is trusted-harness-controlled.
- IOPMP `!enable` is **fail-open**.
- Standalone RSDG formal evidence (`sp11_rsdg_prove`) is **separate** from C.5 hardware integration.

Do **not** claim hardware-enforced fail-closed readiness in C.5.

Source: `results/ieee_access_final/release_candidate/HARDWARE_READINESS_ARCHITECTURE_DECISION.md`.
