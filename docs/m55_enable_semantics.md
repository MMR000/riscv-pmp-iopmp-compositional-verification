# M5.5 HWCFG0.enable semantics

Spec reference: IOPMP v1.0.0-draft5 (upstream regmap comments); cross-check REF v0.8.2 marked
**REVISION_SPECIFIC** where noted.

## Reset

- `hwcfg0_enable_qs` resets to **0** (disabled / bypass enforcement).
- **REVISION_SPECIFIC**: REF v0.8.2 default-enabled narrative differs.

## Write behavior

- Enable bit is **W1SS** (write-1-to-set), bit 31.
- `hwcfg0_enable_we` on HWCFG0 write; cannot clear without reset.
- Observed: post-reset readback shows bit 31 = 0 after W1SS set + reset.

## Enforcement active when

- `iopmp_enabled_o` → `iopmp_enabled_i` in matching logic.
- When 0: matching enters VALID without check (`!iopmp_enabled_i`, matching:171-172).
- When 1 and no matching authorization: ERROR / deny path.

## M55 experiments

| Config | enable | Entry | Write NSAID=0 | Write NSAID=1 (fresh session) |
|--------|--------|-------|---------------|-------------------------------|
| reset only | 0 | none | ALLOW (bypass) | ALLOW (bypass) |
| enable, no entry | 1 | none | DENY | DENY |
| policy nsaid=0 | 1 | yes | ALLOW | DENY (both R/W, no prior auth write) |

Evidence: `results/tables/m55_entry_matrix.csv`, `results/m55/config_dump.txt`
