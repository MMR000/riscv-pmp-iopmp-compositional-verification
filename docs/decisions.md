# Design decisions

## D-001: Simplified PMP/IOPMP first

**Decision:** Implement documented simplified PMP and IOPMP blocks before real core integration.

**Reason:** Isolate compositional question from CPU microarchitecture complexity.

**Alternative:** Start with Ibex PMP immediately.

**Consequence:** Results are valid for the research model; spec alignment deferred to Phase 10.

## D-002: Admission-time authorization

**Decision:** PMP and IOPMP evaluate policy when the transaction is presented to the block. For IOPMP (M2+), metadata (address, length, requester ID, write/read, authorization result) is **latched at admission** and not resampled from live bus signals during the pending/commit pipeline.

**Precise semantics:**

> A transaction admitted under ALLOW retains its admission-time authorization through commit, even if policy later changes to DENY, unless a separate cancellation mechanism exists (none in M2).

**Reason:** Smallest model for M1/M2; matches common bus-firewall placement and enables measurable revocation latency.

**Alternative:** Completion-time/current-policy authorization (Model B in `docs/revocation_models.md`).

**Consequence:** Revoked policies block new admissions immediately but do not retroactively cancel admitted transactions.

## D-003: Fixed memory map

**Decision:** Use documented map starting at `0x1000_0000`.

**Reason:** Clear decode and reproducible tests.

**Alternative:** Dynamic remapping.

**Consequence:** Map changes require explicit documentation update.

## D-004: Fail-closed IOPMP default

**Decision:** IOPMP disabled by default at reset; when enabled, protected region requires explicit valid rule.

**Reason:** Conservative research default.

**Alternative:** Fail-open until configured.

**Consequence:** Reset and configuration sequencing experiments needed in M3.

## D-005: DMA length zero semantics (M2)

**Decision:** `length == 0` is treated as a **4-byte (one word)** transfer for complete-range IOPMP evaluation and DMA master beat sizing.

**Reason:** Aligns DMA master `beat_len` with IOPMP range check; avoids empty-range ambiguity.

**Alternative:** Treat length 0 as an error or as 0 bytes.

**Consequence:** Documented in architecture; overflow uses 33-bit end-address arithmetic with explicit overflow deny.

## D-006: IOPMP admission pipeline (M2)

**Decision:** IOPMP uses a 3-stage pipeline: admission (authorization + latch), hold (1 cycle), pending (bus commit).

**Reason:** Creates measurable distinction between admission time and commit time for policy-transition experiments.

**Alternative:** Single-cycle pass-through (M1 behavior).

**Consequence:** Adds 2 cycles minimum from admission to memory effect; observability signals exposed at SoC top.
