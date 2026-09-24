# Missing evidence and inconsistent numbers

Nothing below is filled in. Fields that were not in the original logs stay `NOT_RECORDED`.

## Missing measurements

1. **Peak RAM** for ARB v1, ARB v2, and any-address no-regrant: not in the SBY stdout. GNU `time` was not captured for those tasks. Only SP-08 tasks have parent RSS.
2. **Z3 version inside SBY logs** for SP-08, ARB, and any-address: logs print `Solver: z3` only.
3. **Yosys / SBY numeric versions inside those same logs**: SBY `--version` is `unknown SBY version`. Yosys 0.68+ sha1 `832843ad0-dirty` is from package environment files, not from the prove stdout.
4. **Per-property ARB-1..ARB-10 runtimes**: one cone. No ten logfiles.
5. **Any-address C.5 random CSV**: 200 per-seed logs exist; `m7_realcore_release_order_random.csv` is absent from that package.
6. **C.5 full-suite wall time**: not recorded.
7. **J2 repaired wall time**: POST_REPAIR_PPA records 1207 s for J3 only.
8. **IOPMP SHA-256 at the repaired J2/J3 OpenROAD runs**: not independently hashed in the PPA package. Those runs predate production `dd7fe6…`.
9. **Z3 internal statistics**: `NOT_REPORTED_BY_TOOL` in the Resubmission CSV.

## Inconsistent or conflicting records

1. **C.5 random seed count**: Production Security Closure reports **50** seeds on IOPMP `ec77c2a9…`. Any-address package reports **200** seeds on IOPMP `dd7fe6…`. Both are real. They are not the same experiment.
2. **J2/J3 “NOT_RERUN” vs later re-run**: Exactly_Once `PPA_VARIANT_PROVENANCE.csv` marks J2/J3 `NOT_RERUN_NO_OPENROAD` on historical arbiter `a6046ee3…` (areas 279752 / 280749). Production_RTL_Repair later published repaired areas 278827 / 277934 on arbiter `20477634…`. After the any-address IOPMP change, OpenROAD was again **not** re-run.
3. **“Arbiter-scoped” vs actual J2/J3 hierarchy**: J2/J3 tops instantiate Ibex PMP + DMA + IOPMP + arbiter (+ domain reset on J3). “Arbiter-scoped” in later notes refers to **which RTL change was re-measured**, not to an arbiter-only netlist.
4. **Formal arbiter hash ≠ production `.sv` hash**: staged `m7_research_arbiter.v` is `4ee4c3fd…` (`ifdef FORMAL` ports). Production `m7/rtl/m7_research_arbiter.sv` is `20477634…`. Not byte-identical.
5. **SP-08 IOPMP ≠ production IOPMP**: SP-08 log `src/iopmp.v` is `527deba4…`. Production is `dd7fe6…`.
6. **Z3 4.13.4 vs 5.0.0**: Resubmission required `tools/z3` 4.13.4. End_to_End `environment.md` records PATH `z3` 5.0.0. This host still has both (`tools/z3/bin/z3` = 4.13.4; conda `z3` = 5.0.0). Any-address `REPRODUCE.sh` prepends `tools/z3/bin`. The SBY logs do not identify which binary ran. Do not pick one.
7. **SP-08 RST-B configured depth**: `config.sby` has **no** `depth` key; the log shows `-t 20`. The Resubmission CSV lists configured_depth=20. Both are consistent with SBY default, but the key is absent from the file.
8. **SP-08 time bases**: GNU wall 0:09.20 vs SBY process 17 s vs SBY clock 9 s for RST-B prove. Prior tables used GNU wall. This freeze lists all three.
9. **IF02-A suite PASS vs event-log SCOREBOARD_FAIL** on the final IOPMP (CPU TXN_ID reuse across reset).
10. **IF03-C/D** empty `err=` in the suite observed string.
11. **Sep-21 `IEEE_Access_Final_Experimental_Evidence.zip`** (`510684cb…`) predates any-address repair and is not this freeze.
12. **Monitor hash pair in Production Security binary hashes**: two different `m7_c5_event_monitor.sv` digests appear in the same `binary_source_hashes.txt` (`f0ea902d…` vs `b8e5f3c7…`) for two listed paths. Not resolved in this freeze; not used as a C.5 pass criterion.

## What is *not* missing (to avoid false gaps)

- Any-address no-regrant prove log exists and shows induction success at step 11.
- Final IF01-A ledger exists and is internally consistent (1/1/1, no DUPLICATE).
- Original IF01-A negative control exists and is preserved separately.
- 200 RAND-ORD logs exist even without the random CSV.
- Repaired J2/J3 metrics JSON files exist and match POST_REPAIR_PPA.md.
