# J2/J3 final_dd7fe6 (sky130hd, 20 ns)

RTL at launch (and after):

- `rtl/iopmp/iopmp.v` `dd7fe6a89f22a9c830615528733b2d51ccfb852ca0966d3991ab1172d06c82c8`
- `m7/rtl/m7_research_arbiter.sv` `204776349008176d2cc2934c0304a27497302cfbe522011ff9358dadf81b4519`

ORFS image: `openroad/orfs@sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277`  
FLOW_VARIANT=`final_dd7fe6` CLOCK_PERIOD=20.0 LEC_CHECK=0  
Host openroad binary: unused (Docker).  
Filelists: `J2.orfs.files` / `J3.orfs.files` (Ibex+PMP+DMA+IOPMP+arbiter; J3 adds domain-reset / `-DRST_B`).  
Not synthesized: C.5 harness, event monitor, target delay, rsdg.

Do **not** reuse prior 278827 / 277934 rows as final.

| Metric | J2 | J3 |
|--------|----|----|
| Wall time (wrapper ELAPSED_SEC) | 1710 | 1415 |
| Exit | 0 | 0 |
| Post-route stdcell area | **277641** | **280331** |
| Setup WNS / TNS | 0.91848 / 0 | 1.26437 / 0 |
| Hold WNS / TNS | 0.298201 / 0 | 0.174777 / 0 |
| Timing | PASS | PASS |
| Route DRC | 0 | 0 |
| GDS | YES `6_final.gds` | YES `6_final.gds` |
| Result | PASS | PASS |

Synthesis hierarchy (Yosys `synth_stat.txt` after flatten): tops `m7_ppa_j2_top` / `m7_ppa_j3_top` plus Ibex `ALU_*_HAN_CARLSON` instances. IOPMP and arbiter are in the filelists and synthesized into the top; they are not named modules after flatten. J3 finish report shows `u.g_domain.u_dom` (domain reset).

JSON: `j2_final_dd7fe6_metrics.json`, `j3_final_dd7fe6_metrics.json`.  
Wrapper logs: `j2_final_dd7fe6_20ns.log`, `j3_final_dd7fe6_20ns.log`.  
Reports copied under `ppa/reports_{j2,j3}/` (synth_stat, 6_finish, DRC). GDS left in ORFS results tree (not in this ZIP).
