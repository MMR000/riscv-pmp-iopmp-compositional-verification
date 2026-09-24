# Reproduction (engineering)

Pin Z3 4.13.4:

```bash
export PATH=/home/mmr/ricv_paper/tools/z3/bin:$PATH
z3 --version   # Z3 version 4.13.4 - 64 bit
yosys -V
python3 tools/SymbiYosys/sbysrc/sby.py --version   # unknown SBY version; git v0.68 b1a1e98c…
```

Formal:

```bash
bash results/m7/evidence_cleanup/formal/run_pinned_proofs.sh
```

C.5 rebuild + selected tests: `scripts/run/run_m7_ibex_c5_build.sh` then the Python snippet in this cleanup (IF01-A / IF02-A / IF03-C / IF03-D).

PPA:

```bash
FLOW_VARIANT=final_dd7fe6 CLOCK_PERIOD=20.0 \
  bash scripts/ppa/run_orfs_m7_docker.sh J2 LOG
FLOW_VARIANT=final_dd7fe6 CLOCK_PERIOD=20.0 \
  bash scripts/ppa/run_orfs_m7_docker.sh J3 LOG
python3 scripts/ppa/extract_orfs_metrics.py J2 final_dd7fe6
python3 scripts/ppa/extract_orfs_metrics.py J3 final_dd7fe6
```

Image: `openroad/orfs@sha256:817b608c69a71fafc7b61baec11b4dc073fb8efb9d2714f9bd3316db4beba277`
