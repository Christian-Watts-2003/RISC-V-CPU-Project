Basys3 wrapper for the modified multi-cycle RV32I core
========================================================

Top module
----------
basys3_modified_top

Use the existing `vivado/basys3_trace.xdc`; the top-level ports are unchanged:
`clk`, `btnC`, `sw[15:0]`, `led[15:0]`, and `uart_tx`.

Sources
-------
- vivado/basys3_modified_top.v
- rtl/modified/rv32i_multicycle.sv
- rtl/single_cycle/controller.sv
- rtl/single_cycle/imm_gen.sv
- rtl/single_cycle/alu.sv
- rtl/single_cycle/branch_unit.sv
- rtl/single_cycle/lsu.sv
- rtl/single_cycle/regfile.sv
- vivado/instruction_trace_uart_reporter.v
- vivado/uart_tx.v

The wrapper ties `mem_ready` high because its data memory is combinational for
reads and synchronous for writes. `CPU_DIVIDER=1` allows the core to run at
full clock speed between trace reports. Increase it to slow execution.

The UART trace fields and test-result events use the same switch mapping as
`BASYS3_TRACE_README.txt`. The modified core's retirement signal is used to
capture one complete instruction report after each instruction finishes.
