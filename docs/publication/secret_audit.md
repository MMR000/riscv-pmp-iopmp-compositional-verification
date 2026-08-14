# Secret / private-data audit

**Date:** 2026-08-14  
**Scope:** research source tree intended for the public artifact (`rtl/`, `m7/`, `scripts/`, `docs/`, `formal/`, `tb/`, `paper/`, `results/tables/`, compact result metadata).  
**Not in public snapshot:** `third_party/` checkouts, toolchains, PDKs, Docker filesystems, Verilator build trees.

## Filename scan

Searched for `.env`, `.env.*`, `*credential*`, `*secret*`, `*.pem`, `*.key`, `id_rsa`, `id_ed25519`.

No matching credential files in the publishable research tree.

## Token / key pattern scan

`gitleaks` is not installed.

Conservative `rg` over `scripts/`, `rtl/`, `m7/`, `docs/`, `formal/`, `tb/`, `paper/`, `results/tables/` found no matches for common live-token prefixes (`ghp_`, `github_pat_`, `sk-`, `AKIA`) or PEM private-key headers.

## Result

**PASS**

No API keys, GitHub tokens, cloud credentials, SSH private keys, or `.env` secrets were found in content that will be published. Historical logs may contain local absolute paths (see `docs/REPRODUCIBILITY.md`); those are machine paths, not credentials.
