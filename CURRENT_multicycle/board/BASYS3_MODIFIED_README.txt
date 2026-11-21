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
- board/performance_summary_uart.v
- board/uart_tx.v

Paths in the source list are relative to the project directory. The default
IMEM_FILE is relative to the project root. Set IMEM_FILE to the absolute
path of this project's sim/test_programs/basys3_rv32i_edgecase.hex, or arrange
Vivado's working directory so the default resolves. Include the HEX file as
a Vivado memory initialization source where required.

The wrapper ties `mem_ready` high because its data memory is combinational for
reads and synchronous for writes. `CPU_DIVIDER=1` allows the core to run at
full clock speed between trace reports. Increase it to slow execution.

Set sw[14] before pressing btnC: 0 selects instruction trace; 1 selects
performance mode. Mode is latched during reset. sw[15] runs/pauses the core.
Both modes use Tera Term at 115200 baud, 8-N-1 with no flow control.

Trace mode: sw[0:8] select PC, instruction, data address, store data,
cycles, instruction count, store count, load data, and result. Opcode class
and test events are always included. The core pauses for each UART report.

Performance mode: the core runs without per-instruction UART pauses. A full
word store of 600D600D (PASS) or DEADFA11 (FAIL) to address 0 ends the
measurement when that store retires, and emits one decimal line:

  RESULT=PASS,CYCLES=27,RETIRED=6,LOADS=1,STORES=2,WAITS=0

CYCLES counts enabled core clock edges including memory waits, starting at
the first enabled fetch after reset and including the final store's WB edge.
RETIRED includes the final marker store. LOADS and STORES count accepted
memory operations, including the marker and test-report stores. WAITS counts
enabled memory-request edges with ready low; it is always zero in this
wrapper because ready is tied high. All counters are 64-bit and wrap on
overflow. Pausing with sw[15] or using CPU_DIVIDER excludes disabled edges,
so CYCLES is not a wall-clock measurement in those cases. Use CPU_DIVIDER=1
and do not pause to calculate elapsed execution time as CYCLES / 100 MHz.
Reset to start another run.

The wrapper gates RAM writes and memory accounting with core_enable and
ready. See ../docs/core.md for the core's enable-qualified handshake.

Vivado ROM warning: add the HEX file to the project and set the top-level
IMEM_FILE parameter to its absolute path, for example
"C:/Users/watts/RISC-V-CPU-PROJECT/CURRENT_multicycle/sim/test_programs/basys3_rv32i_edgecase.hex".
The path must exist on the host. Rerun synthesis and verify that the
readmem warning is gone; an unread ROM is not a valid CPU test.

Compare cores using the same RV32I program, constraints, FPGA and settings.
Counter and UART logic contributes to the board design's resource and timing
reports; inspect the worst paths and do not assume they are inside the CPU.
