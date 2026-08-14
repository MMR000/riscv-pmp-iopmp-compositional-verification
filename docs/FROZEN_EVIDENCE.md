# Frozen evidence

## Experimental freeze

| Field | Value |
|-------|-------|
| Commit | `07ee8931f8e7e75d48168914fffddb31a5e0a091` |
| Internal tag | `checkpoint-m7-phase-d3-ppa-final` |

Scientific results after this freeze in the public artifact are documentation, figures, packaging, or repository-publication metadata unless a later note says otherwise.

Important earlier internal checkpoints (commits in `PROVENANCE.md`): Phase A Ibex PMP, Phase B composition, Phase C reset, Phase C.5 reset closure, Phase D partial / toolchain / D.2 / D.3.

## What the manifest covers

`results/FROZEN_EVIDENCE_MANIFEST.sha256` lists SHA-256 digests for compact scientific files used by the paper:

- `results/tables/*.csv`
- selected compact PPA `metrics*.json` and fairness markdown
- journal figure source CSVs that the generator reads, when present under `results/tables/` or `results/figures/data/`

It does **not** hash omitted build trees, GDS, or solver dumps.

## Verify

From the repository root:

```bash
sha256sum -c results/FROZEN_EVIDENCE_MANIFEST.sha256
```

All paths in the manifest are relative to the repository root.
