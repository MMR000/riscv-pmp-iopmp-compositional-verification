# Security properties

Permanent IDs for experiments and formal work.

## SP-01 CPU Confidentiality

Unauthorized CPU requests must not obtain protected memory contents.

## SP-02 CPU Integrity

Unauthorized CPU writes must not modify protected memory.

## SP-03 DMA Confidentiality

Unauthorized DMA requests must not obtain protected memory contents.

## SP-04 DMA Integrity

Unauthorized DMA writes must not modify protected memory.

## SP-05 Denied Transaction Non-Side-Effect

If a transaction is denied, protected memory state must remain unchanged.

## SP-06 Requester Identity Integrity

Access decisions must correspond to the actual DMA requester identity.

## SP-07 Revocation Safety

After permission revocation, no newly unauthorized transaction may reach protected memory under defined revocation semantics.

## SP-08 Reset Safety

No legal reset sequence may create an interval of unintentional protected-memory accessibility.

## SP-09 Outstanding Transaction Safety

Policy changes must define behavior for transactions accepted before modification but completed afterward.

## SP-10 Concurrent Master Isolation

Simultaneous CPU and DMA traffic must not violate confidentiality or integrity properties.

## SP-11 Secure Admission (M4)

A DMA transaction targeting protected memory must not be admitted while `secure_ready == 0`, unless an explicitly documented fail-closed protection path independently enforces the same security policy.

## SP-12 Reset-Era Commit Safety (M4)

A DMA transaction must not produce an unauthorized protected-memory effect after the security configuration that justified its admission has become invalid.

## SP-13 Recovery Ordering Safety (M4)

DMA functionality may become externally usable only under conditions sufficient to enforce the protected-memory access policy.

## SP-14 Recovery Liveness (M4)

After `secure_ready == 1` and a valid authorized policy exists, authorized DMA traffic must eventually become serviceable. Security must not permanently disable legitimate DMA operation.
