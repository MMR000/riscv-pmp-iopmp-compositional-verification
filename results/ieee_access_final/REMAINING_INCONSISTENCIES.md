# Remaining inconsistencies (not invented)

1. SP-08 RST-B this rerun used production IOPMP `dd7fe6…`. Historical freeze used `527deba4…`. Both PASS; induction step still 3. Runtime/RSS differ (this run GNU 0:28.24 / 322484 kB vs historical 0:09.20 / 274492 kB).
2. ARB v2 this run is slower than the End-to-End archive (clock 106 s vs 43 s) with the same `.sby`. Same PASS / induction step 19. Load/machine variance; properties not changed.
3. Formal arbiter file hash still `4ee4c3fd…` vs production `20477634…`. Body equal after FORMAL-port strip. No synthesized functional difference.
4. J2/J3 areas 277641 / 280331 are **new** `final_dd7fe6` measurements. Do not substitute historical 279752/280749 or repaired 278827/277934.
5. `extract_orfs_metrics.py` writes `clock_period_ns: N/A`; period is 20.0 from the wrapper.
6. IF02-A delay-epoch admission logs `cpu_ic_*` as 0 at bind time; first SRAM write locks payload `0xb0040004`. Not a SCOREBOARD_FAIL.
7. SBY `--version` remains `unknown SBY version`. Git: v0.68 `b1a1e98c…`.
8. Full C.5 200-seed random was **not** re-run this cleanup (only IF01-A, IF02-A, IF03-C/D).
9. Baseline freeze ZIP `IEEE_Access_Experimental_Evidence_Release_Candidate.zip` `67d82af4…` is unchanged and still the prior baseline.
