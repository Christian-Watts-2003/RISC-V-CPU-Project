# Standalone multi-cycle RV32I ASIC sources

Each `.v` file is a complete, CPU-only Verilog source. Select **one file**
and use `rv32i_multicycle` as the synthesis top. All files use the same
module names and ports; do not compile them together or alongside the
modular CPU RTL.

| File | Configuration |
|---|---|
| `multicycle_unoptimized.v` | Current multi-cycle core |
| `multicycle_predecode.v` | Fetch-side predecode only |
| `multicycle_or_select.v` | OR selection only |
| `multicycle_optimized.v` | Predecode and OR selection |

Configurations are fixed in the individual sources. The optimized files
derive from `OPTIMIZED_multicycle`; the unoptimized file derives from
`CURRENT_multicycle`. The decoder still treats RV32M as unsupported. These
are synthesis inputs, not placed-and-routed designs or measured improvements.

## Interface and initialization

`clk` is the rising-edge clock; `reset` is synchronous and active high;
`enable` advances the core. `pc` addresses an external combinational
instruction memory, which supplies `instruction`. Data memory supplies an
aligned 32-bit word on `mem_read_data`, addressed by `mem_addr`. `mem_valid`
and `mem_read` or `mem_write` describe a transaction; `mem_write_data` and
`mem_write_strobe` provide lane-shifted store data and byte enables.
`retire_valid`, `retire_pc` and `retire_instruction` identify retirement.

The memory must accept a transaction **only on an edge where `enable`,
`mem_valid`, and `mem_ready` are all high**. Requests remain asserted through
pauses and waits. Misaligned halfword and word accesses are unsupported.
Instruction/data memories, Basys3 I/O, UART, and counters are not included.

Unlike the FPGA source, the ASIC register file has no `initial` block and is
not reset. Only reads of x0 are guaranteed to return zero. Programs or the
surrounding system must initialize every other register before reading it;
do not assume FPGA power-up zeros in ASIC hardware. This is a deliberate
startup difference, not a fully identical power-on state.

## Verification and implementation

For each file, add it and `multicycle_innovus_tb.sv` to a Vivado simulation
project and run `multicycle_tb` as the simulation top. Do not include any
other CPU RTL files. The testbench initializes registers in simulation to
match the baseline FPGA test setup, checks RV32I, retirement, waits and
pauses, and should finish with:

```text
PASS multi-cycle: 45 retirements, 5 reads, 3 writes
```

Run all four independently. Testbench initialization is not an ASIC reset
mechanism. The standalone sources have not yet been simulated or run through
the ASIC flow.

Synthesize each selected file with the same standard-cell libraries, corner,
top-level timing constraints, and tool settings, then supply the synthesized
netlist and flow-required physical/timing files to Innovus. An ASIC SDC must
be developed for the actual clock, reset, external memory timing, input/output
delays, loads and operating conditions; the Basys3 XDC is not an ASIC
constraint file. Check unconstrained paths and setup/hold after routing.
Measure CPU area and timing consistently; an external combinational ROM's
delay is especially important to the predecode configuration.

## Regeneration

From the repository root, run `python innovus/multicycle/generate_unified.py`.
Use `--check` to detect stale generated files. The generator verifies that
the shared baseline and optimized modules match, removes FPGA-only register
initialization, and fixes the configuration in each standalone source.
