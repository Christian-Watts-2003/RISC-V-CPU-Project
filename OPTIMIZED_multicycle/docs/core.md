# RV32I multi-cycle optimization experiment

This independent copy of `CURRENT_multicycle` preserves its five phases,
instruction and memory interfaces, and RV32I behavior. RV32M encodings remain
unsupported NOPs. Do not compile files from both projects together: they use
the same module names.

The core and `basys3_modified_top` have two compile-time parameters:

| PREDECODE | OR_SELECT | Configuration |
|---:|---:|---|
| 0 | 0 | Decoder and mux baseline |
| 1 | 0 | Fetch-side predecode only |
| 0 | 1 | OR selection only |
| 1 | 1 | Both experiments (default) |

Predecode runs the existing full controller on the fetched instruction and
registers its control bundle at the fetch edge. Decode then uses that bundle
alongside the registered instruction. This moves the controller path into
fetch; it does not add a stage or reduce the cycle count.

OR selection masks and combines mutually exclusive ALU/link candidates in
execute and load/execute candidates in writeback. It is logically equivalent
to the original two-way muxes for known control values. These are experiments
inspired by the paper's early-decode and OR-selection ideas, not a claim of
an exact reproduction or an FPGA improvement. Synthesis may map them to the
same hardware as the original.

Instruction memory must supply the word at `pc` combinationally, including
during fetch. Data memory uses aligned word reads and byte strobes; misaligned
halfword and word accesses are unsupported. Requests remain asserted during
waits and pauses. The external memory must accept a transaction only on an
`enable && mem_valid && mem_ready` edge. The register file is initialized at
startup but is not cleared by reset.

## Local Vivado simulation

Add this folder's `rtl/*.sv` and `sim/multicycle_tb.sv` as sources and select
`multicycle_tb` as the simulation top. The testbench runs all four parameter
combinations together, compares their outputs, state and registers every
cycle, and checks the expected RV32I behavior, retirement, memory waits and
pause behavior. The expected final line is:

```text
PASS all four variants: 45 retirements, 5 reads, 3 writes
```

For board logic, add this folder's `rtl/*.sv` and `board/*.v` as design sources
and run `sim/board_modes_tb.sv` and `sim/performance_summary_tb.sv` separately
as simulation tops. The board test uses the default combined configuration.
These experiments have not yet been simulated or measured in Vivado.

See [board setup](../board/BASYS3_MODIFIED_README.txt) for synthesis,
configuration, ROM, and comparison instructions.
