# Formal assumption register (M3)

Permanent IDs referenced by proofs and experiments.

## FA-01 Trusted configuration

Configuration writes originate from trusted control logic. Baseline formal runs assume `!cfg_write`.

## FA-02 Authentic requester ID

DMA `requester_id` presented at admission is authentic unless an experiment explicitly models corruption.

## FA-03 Deterministic decode

Protected-region decode matches `bus_pkg.vh` constants.

## FA-04 Stable admission metadata

During an outstanding PMP/IOPMP transaction, admission-time privilege/requester/addr/write are stable (enforced via `$stable` assumes where noted).

## FA-05 Model A revocation

Authorization is latched at admission. Policy revoke affects **new** admissions only unless testing Model B (SP-B01).

## FA-06 No bypass

Denied transactions cannot directly bypass the modeled interconnect to protected SRAM.

## FA-07 Synchronous single-clock

Single clock domain; bus stub completes in one cycle unless reset experiments say otherwise.

## FA-08 No spontaneous memory change

Protected SRAM changes only on explicit `prot_req` write beats.

## Property → assumption map

| Property | Assumptions |
|----------|-------------|
| SP-02 | FA-03, FA-04, FA-07, FA-08 + enabled PMP |
| SP-04 | FA-02, FA-03, FA-05, FA-07, FA-08 + enabled IOPMP |
| SP-05 | FA-06, FA-07, FA-08 |
| SP-06 | FA-04, FA-05 |
| SP-07 | FA-05 (Model A) |
| SP-08 | FA-07 + reset model RST-A or RST-B |
| SP-09 | FA-04, FA-05 |
| SP-10 | FA-01–FA-08 |
| SP-B01 | contrast with FA-05 (Model B definition) |
