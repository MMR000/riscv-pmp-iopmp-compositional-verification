# M5.7 Property Dependency (Paper Evidence)

```
Layer 1: IOPMP policy decision (allow/deny)
        |
        v
Layer 2: Transaction binding (route_select / AW-W phase)
        |
        v
Layer 3: AXI enforcement (initiator AW/W handshakes)
        |
        v
Layer 4: Downstream memory integrity (mem_write_event)
```

## Key formal IDs

- **M57-FP-04**: `mem_write_event -> w_context_ok` (central invariant)
- **M57-FP-14**: stale route cannot authorize a denied successor (simulation + directed assert)
- **M57-FA-01..09**: explicit assumptions documented in `docs/m57_formal_assumptions.md`

## Evidence layering

| Layer | M5.5/M5.6 sim | M5.7 formal |
|-------|---------------|-------------|
| Policy correct, path wrong | yes | assumed via env_allow |
| Transaction binding | repair RTL | Verilator on real abstractor |
| Memory effect | mem_changed on DENY | mem_write_event assert |
