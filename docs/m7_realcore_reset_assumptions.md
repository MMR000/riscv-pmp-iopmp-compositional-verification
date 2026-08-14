# M7 Phase C — real-core reset assumptions

## Composition assumptions

1. CPU protection is **only** Ibex internal architectural PMP (no external research `pmp.v`).
2. DMA protection is **only** the project IOPMP on the DMA path.
3. CPU and DMA share one protected SRAM via `m7_research_arbiter`.
4. IOPMP programming in these tests is harness **TRUSTED_CONFIGURATION**, not firmware MMIO.
5. Firmware `PMP_READY` is a software mailbox milestone after CSR writes — **not** an Ibex HW output.

## MEM-RET

Primary RC experiments retain protected SRAM contents across control-domain reset
(`protected_memory_reset_n` held asserted). Sentinel `0x5151A5A5` detects whether
an unauthorized write committed. A memory-wipe variant is out of scope for the
baseline.

## RST-A / RST-B (unchanged semantics)

| | RST-A | RST-B (`-DRST_B`) |
|--|-------|-------------------|
| `iopmp_enable` @ reset | 0 (bypass) | 1 |
| `rule0_valid` @ reset | 0 | 0 |
| Early unauth protected DMA | may commit | denied until valid rule |

FuseSoC boolean `vlogdefine RST_B` must **not** be used (would define `RST_B=0`
and still satisfy `` `ifdef RST_B ``). Phase C uses target `sim` (no define) vs
`sim_rstb` with explicit `-DRST_B`.

## Secure-ready observability

```
sys_secure_ready = PMP_READY && iopmp_enable && rule0_valid && interconnect_reset_n
```

Admission control for DMA remains the IOPMP enable/rule logic above; do not
conflate mailbox readiness with a second independent hardware interlock unless
explicitly implemented.

## Integration limitations (declared)

1. **Late Ibex release:** Holding `cpu_reset_n` low for many cycles after the boot
   fabric is live, then releasing, produced a recursive exception before
   `reset_handler` in this Verilator setup. Recovery tests therefore release the
   CPU with the interconnect; early-DMA tests keep the CPU held (no firmware).
2. **RC-ORD-A..F** do not fully permute independent domain release schedules in
   RTL; they record stamps for the implemented bring-up and check post-recovery
   DMA liveness.
3. **RC-IF-01..03** are classified **INCONCLUSIVE** without deterministic
   mid-transaction cycle control.
4. Random campaign randomizes scenario class and RST-A/B pairing over fixed
   policy/region — not arbitrary PMP entries.

## What is not claimed

- No product vulnerability.
- No “real Ibex RST-B formally proved”.
- No alteration of historical M5.10 formal evidence.
- No change of expected results solely to obtain PASS.
