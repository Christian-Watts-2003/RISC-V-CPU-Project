# Single-cycle tests

From the repository root, run `bash singlecycle/scripts/test_single_cycle.sh`
with Icarus Verilog installed. The script can also be invoked by absolute
path from another directory. It compiles the modular `singlecycle/rtl/`
sources and `sim/Single Cycle TBs/single_cycle_tb.sv`, not the separate
Innovus bundle or another project.

The existing integration and controller tests expect RV32M operations,
whereas the modular controller currently makes them NOPs. Those RV32M checks
are expected to fail until the design or tests are intentionally reconciled.
The tests were not run during this cleanup.
