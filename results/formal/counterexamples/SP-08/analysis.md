# SP-08 counterexample analysis

## Property

SP-08 (reset safety baseline): before `secure_ready`, unauthorized protected-memory DMA effect forbidden.

## Formal task

`sp08_reset.sby` — harness `formal_reset_tb.v`, RST-A fail-open defaults.

## Result

COUNTEREXAMPLE at BMC step 1 (expected under RST-A).

## Classification

`RESET_ASSUMPTION_DEPENDENCY` — not classified as SECURITY_FAILURE.

## Root cause

`security_config` reset state has `iopmp_enable=0` and `rule0_valid=0` while PMP remains enabled (`pmp_enable=1`). IOPMP `enable=0` fail-open path allows in-region DMA when DMA reset releases before secure configuration is valid.

## Comparison with M2

M2 normal-operation tests assume configured secure baseline (Model A). This counterexample exercises reset ordering explicitly excluded from M2.

## Reproducible

Yes — `make reset-tests` or `formal/sby/sp08_reset.sby`.

## Trace

See `trace.vcd` in this directory.
