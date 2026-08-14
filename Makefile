# RISC-V compositional isolation research build

export PATH := $(HOME)/miniconda3/bin:$(PATH)
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
PYTEST := python3 -m pytest
TB := $(ROOT)/tb/cocotb
Z3 := $(ROOT)/tools/z3/bin
SBY := python3 $(ROOT)/tools/SymbiYosys/sbysrc/sby.py

.PHONY: all m1 m2 m3 m35 m4 m4-sim m4-directed m4-random m4-formal m4-performance m4-synth m4-waveforms m4-full formal formal-smoke formal-full formal-m35 reset-tests reproduce env test clean

all: m2

env:
	@./scripts/setup/check_environment.sh

test: m2

m1: env
	@mkdir -p results/simulation results/formal/counterexamples
	cd $(TB) && $(PYTEST) test_soc_top.py -v
	@cp -f $(TB)/sim_build/soc_top.fst results/simulation/m1_soc_top.fst 2>/dev/null || true
	@echo "M1 complete. See results/simulation/m1_summary.md"

m2: m1
	@mkdir -p results/simulation results/tables results/simulation/waveforms
	rm -rf $(TB)/sim_build
	cd $(TB) && $(PYTEST) test_m2_runner.py -v
	@cp -f $(TB)/sim_build/soc_top.fst results/simulation/m2_soc_top.fst 2>/dev/null || true
	@cp -f results/simulation/m2_soc_top.fst results/simulation/waveforms/m2_bnd_b7_cross_boundary_denied.fst
	@cp -f results/simulation/m2_soc_top.fst results/simulation/waveforms/m2_con_c8_cpu_dma_same_addr.fst
	@cp -f results/simulation/m2_soc_top.fst results/simulation/waveforms/m2_pt1_allow_to_deny_before_request.fst
	@cp -f results/simulation/m2_soc_top.fst results/simulation/waveforms/m2_pt3_allow_to_deny_inflight.fst
	@cp -f results/simulation/m2_soc_top.fst results/simulation/waveforms/m2_rid4_requester_id_change_inflight.fst
	@python3 scripts/analysis/build_results.py --m2
	@echo "M2 complete. See results/simulation/m2_summary.md"

reproduce: m2
	@python3 scripts/analysis/build_results.py

formal-smoke:
	@FORMAL_MODE=smoke PATH="$(Z3):$(PATH)" bash scripts/run/run_formal.sh 2

formal-full:
	@FORMAL_MODE=full PATH="$(Z3):$(PATH)" bash scripts/run/run_formal.sh 4

formal: formal-smoke

reset-tests: formal-full

m3: m2 formal-full

formal-m35:
	@bash scripts/run/run_formal_m35.sh 4

m35: m2 formal-m35

m4-sim:
	@bash scripts/run/run_m4_sim.sh

m4-directed:
	@bash scripts/run/run_m4_directed.sh

m4-random:
	@bash scripts/run/run_m4_random.sh

m4-performance:
	@bash scripts/run/run_m4_performance.sh

m4-synth:
	@bash scripts/run/run_m4_synth.sh

m4-waveforms:
	@bash scripts/run/run_m4_waveforms.sh

m4-formal: formal-m35
	@PATH="$(Z3):$(PATH)" bash scripts/run/run_m4_formal.sh

m4-smoke: m35 m4-sim

m4: m35 m4-sim m4-synth m4-formal
	@python3 scripts/analysis/aggregate_m4.py
	@echo "M4 complete. See results/tables/m4_configuration_comparison.csv"

m4-full: m35 m4-directed m4-random m4-formal m4-performance m4-synth m4-waveforms
	@python3 scripts/analysis/aggregate_m4.py
	@echo "M4 full evidence. See results/tables/m4_configuration_comparison.csv"

m5-ref-build:
	@bash scripts/run/run_m5_ref_build.sh

m5-ref-tests: m5-ref-build
	@bash scripts/run/run_m5_ref_tests.sh

m5-differential: m5-ref-tests
	@python3 m5/analysis/run_m5_differential.py

m5-rtl-build:
	@bash scripts/run/run_m5_rtl_build.sh

m5-rtl-directed: m5-rtl-build
	@bash scripts/run/run_m5_rtl_directed.sh

m5-rtl-random: m5-rtl-build
	@bash scripts/run/run_m5_rtl_random.sh

m5-ref-rtl-diff:
	@python3 m5/analysis/run_m5_ref_rtl_diff.py

m5-full: m5-ref-tests m5-differential m5-rtl-directed m5-ref-rtl-diff
	@cp -f results/m5/rtl/rtl_results.csv results/tables/m5_rtl_results.csv 2>/dev/null || true
	@echo "M5 full evidence. See results/m5/ and results/tables/m5_*"

m5-rtl-tests: m5-rtl-directed

m5: m5-full

m55-build:
	@bash scripts/run/run_m55_build.sh

m55-baseline: m55-build
	@bash scripts/run/run_m55_baseline.sh

m55-nsaid: m55-build
	@bash scripts/run/run_m55_nsaid.sh

m55-permissions: m55-build
	@bash scripts/run/run_m55_permissions.sh

m55-config: m55-build
	@bash scripts/run/run_m55_config.sh

m55-random: m55-build
	@bash scripts/run/run_m55_random.sh

m55: m55-baseline m55-nsaid m55-permissions m55-config m55-random
	@python3 scripts/analysis/aggregate_m55.py
	@echo "M5.5 complete. See results/m55/m55_summary.md"

.PHONY: m56 m56-build m56-before m56-fix m56-regression m56-timing m56-stale-route m56-random m56-formal m56-latency

m56-build:
	@IOPMP_FIX=proper bash scripts/run/run_m56_build.sh

m56-before:
	@bash scripts/run/run_m56.sh before

m56-fix: m56-build
	@bash scripts/run/run_m56.sh regression

m56-regression: m56-fix

m56-timing: m56-build
	@bash scripts/run/run_m56.sh timing

m56-stale-route: m56-build
	@bash scripts/run/run_m56.sh stale-route

m56-random: m56-build
	@bash scripts/run/run_m56.sh random

m56-formal:
	@bash scripts/run/run_m56.sh formal

m56-latency: m56-build
	@bash scripts/run/run_m56.sh latency

m56: m55-baseline m56-before m56-fix m56-timing m56-stale-route m56-random m56-formal
	@bash scripts/run/run_m56.sh reset
	@bash scripts/run/run_m56.sh latency
	@bash scripts/run/run_m56.sh fix-compare
	@bash scripts/run/run_m56.sh aggregate
	@echo "M5.6 complete. See results/m56/m56_summary.md"

.PHONY: m57 m57-verilator m57-formal m57-regression

m57-verilator:
	@M57_VARIANT=original ROOT=$(ROOT) bash scripts/run/run_m57_verilator_assert.sh
	@M57_VARIANT=proper ROOT=$(ROOT) bash scripts/run/run_m57_verilator_assert.sh

m57-formal:
	@M57_VARIANT=original M57_DEPTH=16 bash scripts/run/run_m57_formal.sh || true
	@M57_VARIANT=proper M57_DEPTH=16 bash scripts/run/run_m57_formal.sh || true
	@M57_VARIANT=original M57_DEPTH=32 bash scripts/run/run_m57_formal.sh || true
	@M57_VARIANT=proper M57_DEPTH=32 bash scripts/run/run_m57_formal.sh || true

m57-regression:
	@bash scripts/run/run_m57_regression.sh

m57: m57-verilator m57-formal m57-regression
	@python3 scripts/analysis/aggregate_m57_formal.py --finalize
	@echo "M5.7 complete. See results/m57/m57_summary.md"

.PHONY: m58 m58-bmc m58-prove m58-formal

m58-bmc:
	@M58_VARIANT=original M58_DEPTH=64 bash scripts/run/run_m58_formal.sh
	@M58_VARIANT=proper M58_DEPTH=64 bash scripts/run/run_m58_formal.sh

m58-prove:
	@M58_VARIANT=proper M58_MODE=prove M58_DEPTH=32 bash scripts/run/run_m58_formal.sh

m58-induction:
	@M58_VARIANT=proper M58_MODE=induction M58_DEPTH=32 bash scripts/run/run_m58_formal.sh

m58-pdr: m58-prove

m58-formal: m58-bmc m58-induction m58-pdr

m58: m58-formal m57-verilator
	@echo "M5.8 complete. See results/m58/m58_summary.md"

.PHONY: m59 m59-bmc m59-prove m59-formal m59-ladder

m59-bmc:
	@M59_VARIANT=original M59_ENV_LEVEL=0 M59_DEPTH=128 bash scripts/run/run_m59_formal.sh
	@M59_VARIANT=proper M59_ENV_LEVEL=4 M59_DEPTH=512 bash scripts/run/run_m59_formal.sh

m59-prove:
	@M59_VARIANT=proper M59_ENV_LEVEL=4 M59_MODE=prove M59_DEPTH=32 bash scripts/run/run_m59_formal.sh

m59-ladder:
	@python3 scripts/m59/run_assumption_ladder.py

m59-formal: m59-bmc m59-prove

m59: m59-formal m57-verilator
	@python3 scripts/m59/replay_fix2_formal_ce.py
	@echo "M5.9 complete. See results/m59/m59_summary.md"

.PHONY: m510 m510-formal m510-matrix

m510-formal:
	@bash scripts/run/run_m4_formal.sh
	@M59_VARIANT=original M59_ENV_LEVEL=0 M59_DEPTH=128 bash scripts/run/run_m59_formal.sh
	@M59_VARIANT=proper M59_ENV_LEVEL=4 M59_DEPTH=512 bash scripts/run/run_m59_formal.sh || true

m510-matrix:
	@python3 scripts/analysis/aggregate_m510.py

m510: m510-formal m510-matrix m57-verilator m55-baseline m56-regression
	@echo "M5.10 complete. See results/m510/m510_summary.md"

.PHONY: paper paper-clean paper-artifacts

paper-artifacts:
	@python3 scripts/analysis/generate_paper_artifacts.py

paper: paper-artifacts
	@mkdir -p paper/build results/m6
	@cd paper && ( \
	  export TEXINPUTS=./vendor//:$$TEXINPUTS; \
	  if command -v latexmk >/dev/null 2>&1; then \
	    latexmk -pdf -interaction=nonstopmode -output-directory=build main.tex; \
	  else \
	    pdflatex -interaction=nonstopmode -output-directory=build main.tex && \
	    bibtex build/main || true && \
	    pdflatex -interaction=nonstopmode -output-directory=build main.tex && \
	    pdflatex -interaction=nonstopmode -output-directory=build main.tex; \
	  fi \
	) 2>&1 | tee ../results/m6/paper_build.log
	@test -f paper/build/main.pdf && echo "Paper PDF: paper/build/main.pdf" || (echo "LaTeX build failed; see results/m6/paper_build.log" && exit 1)

paper-clean:
	@rm -rf paper/build
	@rm -f results/m6/paper_build.log

.PHONY: m7 m7-realcore m7-ibex-composed m7-ibex-reset m7-ibex-reset-inflight m7-ibex-release-orders m7-reset m7-multimaster m7-ppa m7-ppa-full m7-performance m7-formal

m7-realcore:
	@bash scripts/run/run_m7_realcore.sh

m7-ibex-composed:
	@bash scripts/run/run_m7_ibex_composed.sh

m7-ibex-reset:
	@bash scripts/run/run_m7_ibex_reset.sh

m7-ibex-reset-inflight:
	@bash scripts/run/run_m7_ibex_c5_build.sh
	@python3 scripts/analysis/run_m7_phase_c5_tests.py \
	  --sim-a results/m7/realcore_reset_c5/rsta/sim-verilator/Vm7_ibex_c5_composed_top \
	  --sim-b results/m7/realcore_reset_c5/rstb/sim-verilator/Vm7_ibex_c5_composed_top \
	  --only inflight

m7-ibex-release-orders:
	@test -x results/m7/realcore_reset_c5/rstb/sim-verilator/Vm7_ibex_c5_composed_top || bash scripts/run/run_m7_ibex_c5_build.sh
	@python3 scripts/analysis/run_m7_phase_c5_tests.py \
	  --sim-a results/m7/realcore_reset_c5/rsta/sim-verilator/Vm7_ibex_c5_composed_top \
	  --sim-b results/m7/realcore_reset_c5/rstb/sim-verilator/Vm7_ibex_c5_composed_top \
	  --only orders

m7-reset:
	@bash scripts/run/run_m7_reset.sh

m7-multimaster:
	@bash scripts/run/run_m7_multimaster.sh

m7-ppa:
	@bash scripts/run/run_m7_ppa.sh

m7-ppa-full:
	@bash scripts/run/run_m7_ppa_full.sh

m7-performance:
	@python3 scripts/analysis/run_m7_realcore_performance.py --random-n 500

m7-formal:
	@bash scripts/run/run_m7_formal.sh

m7: m7-reset m7-multimaster m7-ppa m7-performance
	@bash scripts/run/run_m7_realcore.sh || true
	@bash scripts/run/run_m7_formal.sh || true
	@python3 scripts/analysis/aggregate_m7.py
	@echo "M7 complete. See results/m7/m7_summary.md"

clean:
	rm -rf sim_build results/simulation/sim_build results/simulation/*.xml
	find $(TB) -name '__pycache__' -type d -exec rm -rf {} + 2>/dev/null || true
