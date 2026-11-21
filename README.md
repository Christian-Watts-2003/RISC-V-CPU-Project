# RISC-V CPU project

The active design is a multi-cycle RV32I CPU targeting the Basys3 FPGA. The
owner reports that this design has been verified and meets timing; the timing
report is not in this repository.

## Project directories

| Directory | Purpose |
|---|---|
| [CURRENT_multicycle](CURRENT_multicycle/docs/core.md) | Current multi-cycle RV32I core, testbench, and Basys3 trace wrapper. |
| [multicycle_MULDIV](multicycle_MULDIV/docs/core.md) | Independent copy of the current core with the existing MulDiv source retained for future integration; RV32M is not enabled. |
| [multicycle_MULDIV_test](multicycle_MULDIV_test/docs/core.md) | Separate experimental RV32M integration with a directed testbench and Basys3 synthesis top. |
| [singlecycle](singlecycle/docs/core.md) | Independent single-cycle RTL, tests, board files, and separate Innovus source. |
| [legacy/to-be-deleted](legacy/to-be-deleted/README.md) | Pipeline, optimization experiments, superseded files, and old documents retained for review, not deleted. |

Each project contains its own RTL, simulation assets, board files, scripts,
and documentation. Compile one project and one specified source set at a
time: module names are reused across projects and the Innovus bundle.

To run the new test locally with Icarus Verilog:

```sh
bash CURRENT_multicycle/scripts/test_multicycle.sh
```

See the project documentation for source lists, memory behavior, known
limitations, and Vivado image paths. The owner reported a passing run of
the current multi-cycle testbench in Vivado. The general [RV32I instruction reference](docs/isa_reference.md)
and [MIT license](LICENSE) remain at the repository level.
