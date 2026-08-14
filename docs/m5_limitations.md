# M5 limitations

1. **M4-IOPMP frozen** — no RTL changes to M1–M4 evidence; differential uses cocotb probe only.
2. **REF-IOPMP is C reference model**, not cycle-accurate RTL; timing/stall-buffer behavior not compared.
3. **C0 mapping** — M4 C0 fail-open reset default ≠ REF `enable=0` bypass when IOPMP remains enabled in-path.
4. **`m5_secure_ready`** — harness concept only; not an IOPMP architectural signal.
5. **Specification status** — IOPMP v0.8.2 is a **development specification**, not ratified standard (`docs/m5_spec_status.md`).
6. **RTL-IOPMP** — targets v1.0.0-draft5; three-way comparison incomplete until AXI adapter exists.
7. **Range/partial-hit** — spot checks only on REF; full M2 reproduction not exhaustive in M5A.
8. **CPU abstract** — no Ibex/CVA6 integration (by design).
9. **Formal verification** — optional for M5; not attempted on third-party RTL.
10. **RTL unauthorized write** — unmapped NSAID=1 write observed ALLOW while read DENY; under investigation, not classified as vulnerability.
11. **RTL random campaign** — 500 seeds, functional not cycle-accurate.
