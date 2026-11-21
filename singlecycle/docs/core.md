# Single-cycle reference

The modular RTL in `rtl/` implements RV32I arithmetic, branches, jumps,
loads and stores. The controller currently treats RV32M encodings as
unsupported NOPs, even though the standalone combinational `muldiv.sv` and
its datapath connection are present. `FENCE`, `SYSTEM`, and illegal
encodings are also NOPs. Misaligned halfword/word accesses are unsupported.

The separate `innovus/single_cycle_Innovus.v` is a historical unified source
with its own decoder that enables RV32M; it must not be compiled together
with modular RTL because module names overlap. Its combinational divide and
remainder can create long timing paths. See
[Innovus notes](single_cycle_Innovus_README.txt).

The existing controller and integration testbenches expect RV32M to be
enabled in the modular controller, so those checks do not match the current
modular RTL. They are retained without changing the RTL or claiming they
pass. See [simulation notes](simulation.md) and the board readmes.
