# Revocation models (M2)

## Model A — Admission-Time Revocation (current baseline)

**Definition:** Authorization is evaluated and captured when the IOPMP accepts a DMA request at admission. A transaction admitted under ALLOW may complete even if policy becomes DENY before memory commit.

**Baseline property (SP-07 under Model A):**

> After DENY becomes effective, no **new** unauthorized transaction may be **admitted**.

Outstanding admitted transactions are measured separately (SP-09).

## Model B — Strong/Immediate Revocation

**Definition:** Once policy becomes DENY for a region/requester, no transaction—including previously admitted transactions—may subsequently modify protected memory.

**Not implemented in M2.** Supporting Model B would require transaction cancellation, quiescence, or completion-time re-check.

## M2 goal

1. Document both models.
2. Test current design under Model A.
3. Quantify revocation visibility and completion latency under Model A.
4. Record where Model A differs from Model B (admitted transactions may complete after revoke).

## Metrics

| Metric | Definition |
|--------|------------|
| `revocation_visibility_latency` | Cycles from configuration write until first request evaluated under new policy |
| `revocation_completion_latency` | Cycles from configuration write until no admitted old-policy transaction remains pending |

Raw measurements: `results/tables/m2_transition_latency.csv`

## Mitigation

Safe quiescence protocol is **not** implemented in M2 (deferred until baseline behavior is characterized).
