# M5.7 formal assumptions

| ID | Assumption |
|----|------------|
| M57-FA-01 | Single outstanding write transaction |
| M57-FA-02 | Stable AW payload under valid&&!ready |
| M57-FA-03 | Stable W payload under valid&&!ready |
| M57-FA-04 | Single-beat writes (len=0, w.last=1) |
| M57-FA-05 | No read traffic on abstractor slave port |
| M57-FA-06 | IOPMP grant within 8 cycles of transaction_en |
| M57-FA-07 | Initiator B response within 16 cycles of W handshake (fairness) |
| M57-FA-08 | Environment allow stable per transaction |
| M57-FA-09 | Verilator assertion checking used when Yosys BMC unavailable (M57-FA-TOOL) |

## M57-FA-TOOL Yosys elaboration limit

Yosys 0.68 cannot elaborate full vendor `axi_pkg` / `axi_err_slv` / parameterized structs. SymbiYosys BMC recorded INCONCLUSIVE. Real RTL checked via Verilator `--assert` closure (abstractor + axi_demux + axi_err_slv).
