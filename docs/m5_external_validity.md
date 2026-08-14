# M5 external validity (updated after M5B)

## EV levels

| Claim | Level |
|-------|-------|
| M4 C1 minimal sufficient (abstract) | EV-0 |
| C1 / enforce pre-config deny (REF) | **EV-1** |
| Deny-by-default when `enable=1` (RTL) | **EV-2** |
| Authorized policy on RTL | **EV-2** |

## External-validation gate

**M5A:** Result A — REF supports enable bypass/enforce distinction.

**M5B:** RTL functional integration **COMPLETE** for central reset/enforcement question.

## CI-IOPMP-01 (evidence-supported draft)

> Before trusted IOPMP configuration is established, the SoC must ensure device-originated transactions to protected memory are subject to a **deny-by-default enforcement path** when IOPMP checking is enabled.

Observations:

- **REF-IOPMP:** `enable=1` at reset (adapter) → pre-config DENY
- **RTL-IOPMP:** `enable=0` at reset → pre-config ALLOW until firmware sets `enable=1`
- **M4-IOPMP:** C1 fail-closed internal defaults when IOPMP in-path

## Key revision difference

RTL reset is **fail-open** (`enable=0`); REF default adapter uses **fail-closed** (`enable=1`). Not a contradiction — different reset contracts. Security requires explicit enable programming on RTL.
