# M7 PPA limitations

1. **Toolchain**: Official ORFS Docker gates (nangate45/gcd and sky130hd/ibex) **PASS** as of Phase D.1. Host ORFS submodules remain uninitialized; tools come from `openroad/orfs:latest`. Project J0–J3 physical PPA has not been run yet. On this i9-14900KF host, `LEC_CHECK=0` is required because image `kepler-formal` uses AVX-512.
2. **No fabricated metrics**: Area, Fmax, power, and cell counts remain blank for project J0–J3 until those jobs run. Official GCD/Ibex validation numbers are toolchain evidence only, not research-design PPA.
3. **Memory blackbox**: SRAM arrays excluded; logic-only comparison may under-estimate system area if memory macros dominate silicon.
4. **J4 N/A**: FIX-2 binding is on AXI abstractor, not research IOPMP on real-Ibex path.
5. **Single platform**: Official SKY130HD Ibex validation flow executed; project J0–J3 SKY130HD PPA and Nangate45 sensitivity not run.
6. **Not silicon validation**: ORFS results (when available) are implementation estimates only.
7. **C.5 tag**: `checkpoint-m7-phase-c5-reset-closure` not yet applied; C.5 matrices present in working tree with recorded SHA256.
8. **Performance vs PPA**: Cycle-level latency is simulation evidence; must not be confused with post-route timing.
