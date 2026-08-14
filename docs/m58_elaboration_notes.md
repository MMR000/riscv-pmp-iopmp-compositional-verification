# M5.8 Elaboration Notes

## Goal

Elaborate `formal_m57_fullrtl_write_path_tb.sv` with real `rv_iopmp_data_abstractor_axi`, `axi_demux`, and `axi_err_slv` using `read_slang`.

## Blockers encountered (M5.7 / Yosys 0.68 read -sv)

| Blocker | Error | Classification |
|---------|-------|----------------|
| Parameterized types default to `logic` | invalid member access on `axi_req_t` | TOOLCHAIN_LIMITATION |
| Missing vendor cells | unknown module `fifo_v3` | ELABORATION_CLOSURE |
| Missing `axi/typedef.svh` | include path | ELABORATION_CLOSURE |
| Missing `rv_iopmp_reg_pkg` | unknown package | ELABORATION_CLOSURE |
| SVA in harness | unsupported SVA feature | PROPERTY_ENCODING |

## Fixes applied (semantics preserved)

1. **read_slang** with full vendor closure + include paths (`-I. -Ivendor -Iinclude`).
2. **`scripts/m58/prepare_formal_rtl.sh`** stages packages, vendor, axi includes, abstractor variant.
3. **`FORMAL` ifdef** in harness:
   - `clk`/`rst_n` as formal inputs (wire)
   - Yosys `assert`/`assume`/`cover` instead of SVA (Verilator path unchanged)
   - No directed stimulus under `FORMAL`
4. Wire ordering fix: declare `ini_w_hs` before `mem_write_event`.

## Elaboration result

**SUCCESS** — see `results/formal/m58/elaboration/read_slang_full_harness_original.log`

## Semantic changes

None to production RTL. Harness-only formal encoding for Yosys compatibility.
