# Multi-cycle RV32M integration experiment

This independent experiment copies the current multi-cycle core and enables
RV32M in its local controller. Decode registers the MulDiv operation and
operands; the existing combinational `muldiv` produces a candidate result
captured in execute and written back like an ALU result. All eight RV32M
operations are enabled. The existing unit asserts `valid` with `start`; it
is not an iterative handshake. Instruction cycle counts are unchanged.

The divider and remainder are combinational. Their resource use and delay
may be substantial and may not meet 100 MHz. Directed simulation passed as
reported by the owner; timing has not been qualified. The original `CURRENT_multicycle/` and dormant
`multicycle_MULDIV/` remain unchanged.

As in the original core, memory requests remain asserted while `enable` is
low and are accepted only on an `enable && mem_valid && mem_ready` edge.
The experimental Basys3 wrapper gates RAM and trace updates accordingly.
The register file initializes at startup but reset does not clear it.

## Vivado behavioral simulation

Add **only** `multicycle_MULDIV_test/rtl/*.sv` as design sources and
`multicycle_MULDIV_test/sim/muldiv_integration_tb.sv` as a simulation source.
Set `muldiv_integration_tb` as simulation top and run all. It prints each
retirement and checks all RV32M operations, signed/unsigned high products,
division and remainder corner cases, dependencies, x0, an illegal encoding,
memory, and pause/wait behavior. It has a timeout and ends with
`PASS RV32IM integration` only after all checks.

The separate `sim/multicycle_tb.sv` retains the earlier RV32I regression
with its M-as-NOP case replaced by an illegal encoding. Select
`multicycle_tb` as simulation top to run it separately. The scripts
`scripts/test_muldiv.sh` and `scripts/test_multicycle.sh` are optional local
Icarus alternatives. The owner reported a passing Vivado run of
`muldiv_integration_tb` with 33 retirements, 1 read, and 1 write.

For board reporting checks, add local `rtl/*.sv` and `board/*.v` as design
sources and set `sim/board_modes_tb.sv` as simulation top. It checks
performance counters, pass/fail summaries, paused stores and trace pauses.
`sim/performance_summary_tb.sv` separately checks decimal formatting,
including 64-bit values. These new tests have not yet been simulated.

## Synthesis and implementation

See [Basys3 setup](../board/BASYS3_MULDIV_README.txt) for the synthesis
top, sources, memory image, constraints, and timing-report guidance.
