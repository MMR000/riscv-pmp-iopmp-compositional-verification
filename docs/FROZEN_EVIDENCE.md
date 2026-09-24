# Frozen evidence

## Experimental freeze (current public tag)

| Field | Value |
|-------|-------|
| Public tag | `access-2026-41377-experimental-freeze` |
| Public commit | peel of that tag (`git rev-parse access-2026-41377-experimental-freeze^{}`) |
| Manuscript | Access-2026-41377 |

Do **not** point this tag at the old internal commit `07ee8931f8e7e75d48168914fffddb31a5e0a091`. That commit predates the repository synchronization.

## Authoritative packages

| Package | SHA-256 |
|---------|---------|
| `IEEE_Access_Experimental_Evidence_Release_Candidate.zip` | `67d82af4705cd9f8f19564f6c22ce60cd6e8647bfd561c8f40184d50e240f486` |
| `IEEE_Access_Final_Evidence_Cleanup.zip` | `7a91a075719e73eb4cad35450c737fa594f7b1b1135936015994d4d60ce31d91` |

Copies: `results/ieee_access_final/packages/`. Cleanup supersedes conflicting values.

## Earlier snapshots (preserved)

| Snapshot | Identity |
|----------|----------|
| Public `artifact-v1.0` | `5c8e2448c2d02835ce8047e428ee70a43278f881` |
| Internal D.3 scientific freeze | `07ee8931f8e7e75d48168914fffddb31a5e0a091` (`checkpoint-m7-phase-d3-ppa-final`) |

## Production RTL

| File | SHA-256 |
|------|---------|
| `rtl/iopmp/iopmp.v` | `dd7fe6a89f22a9c830615528733b2d51ccfb852ca0966d3991ab1172d06c82c8` |
| `m7/rtl/m7_research_arbiter.sv` | `204776349008176d2cc2934c0304a27497302cfbe522011ff9358dadf81b4519` |

Formal staged arbiter `4ee4c3fd…` is not byte-identical (FORMAL observation ports). Functional body equal after strip. No synthesized functional difference.

## Manifest

`results/FROZEN_EVIDENCE_MANIFEST.sha256` hashes compact scientific files (`results/tables/*.csv` and selected metrics). It does not hash omitted GDS or solver dumps.

```bash
sha256sum -c results/FROZEN_EVIDENCE_MANIFEST.sha256
python3 scripts/artifact/check_artifact.py
```
