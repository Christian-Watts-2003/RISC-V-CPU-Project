Basys3 wrapper for the modified multi-cycle RV32I core
========================================================

Top module
----------
basys3_modified_top

Use `board/basys3_trace.xdc`; the top-level ports are:
`clk`, `btnC`, `sw[15:0]`, `led[15:0]`, and `uart_tx`.

The shared XDC creates a 100 MHz `sys_clk` (10 ns period). Board-level switch
and LED/UART paths are excluded because they have no external synchronous
clock; internal register-to-register paths remain constrained to 10 ns.

Sources
-------
- board/basys3_modified_top.v
- rtl/rv32i_multicycle.sv
- rtl/controller.sv, rtl/imm_gen.sv, rtl/alu.sv, rtl/branch_unit.sv,
  rtl/lsu.sv, rtl/regfile.sv
- board/instruction_trace_uart_reporter.v
- board/uart_tx.v

Paths in the source list are relative to the project directory. The default
IMEM_FILE is relative to the project root. Set IMEM_FILE to the absolute
path of this project's sim/test_programs/basys3_rv32i_edgecase.hex, or arrange
Vivado's working directory so the default resolves. Include the HEX file as
a Vivado memory initialization source where required.

The wrapper ties `mem_ready` high because its data memory is combinational for
reads and synchronous for writes. `CPU_DIVIDER=1` allows the core to run at
full clock speed between trace reports. Increase it to slow execution.

sw[15] enables execution. sw[0:8] select PC, instruction, data address,
store data, cycles, instruction count, store count, load data, and result.
Opcode class and test events are always included. The UART uses 115200 baud,
8-N-1 by default. The core's retirement signal starts each report.

The wrapper does not gate RAM writes or store counting with core_enable.
If paused or divided while a store is in the memory phase, the same write and
count may repeat. See ../docs/core.md before attaching side-effecting memory.
