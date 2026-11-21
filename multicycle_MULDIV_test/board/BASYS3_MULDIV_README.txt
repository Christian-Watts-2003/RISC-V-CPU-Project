Basys3 multi-cycle RV32M experiment
==================================

Vivado design sources, relative to multicycle_MULDIV_test:

  rtl/rv32im_multicycle.sv
  rtl/controller.sv
  rtl/imm_gen.sv
  rtl/alu.sv
  rtl/branch_unit.sv
  rtl/lsu.sv
  rtl/regfile.sv
  rtl/muldiv.sv
  board/basys3_muldiv_top.v
  board/instruction_trace_uart_reporter.v
  board/performance_summary_uart.v
  board/uart_tx.v

Set basys3_muldiv_top as the synthesis top. Add board/basys3_trace.xdc as
the constraints source for synthesis and implementation. It assigns Basys3
clock, button, switch, LED, and UART pins and constrains clk to 10 ns
(100 MHz). It declares the static buttons/switches and asynchronous
LED/UART outputs false paths; internal register-to-register paths remain
timed. Review those exceptions if the I/O environment changes.

The default IMEM_FILE is sim/test_programs/basys3_muldiv.hex relative to
this project directory. Vivado may run synthesis from a different directory.
Add the HEX as a memory initialization source and set the IMEM_FILE
parameter to its absolute path, for example
"C:/Users/watts/RISC-V-CPU-PROJECT/multicycle_MULDIV_test/sim/test_programs/basys3_muldiv.hex".
Verify that path exists on the host, rerun synthesis, and confirm the
readmem warning is gone. An unread ROM is not a valid CPU test.
The image includes all eight RV32M instructions and checks divide-by-zero
and signed overflow; it emits per-test events and overall PASS/FAIL markers.
Regenerate it with python sim/test_programs/generate_basys3_muldiv.py.

Set sw[14] before pressing btnC: 0 selects instruction trace; 1 selects
performance mode. Mode is latched during reset. sw[15] runs/pauses the core.
Both modes use Tera Term at 115200 baud, 8-N-1 with no flow control.

In trace mode sw[8] enables RESULT; TEST and OP are always emitted. TEST
reports the test ID; RESULT reports the overall marker. RV32M instructions
are labeled OP=ALU by the shared opcode-class reporter. The CPU pauses for
each report.

In performance mode the core runs without per-instruction UART pauses. A
full word store of 600D600D (PASS) or DEADFA11 (FAIL) to address 0 ends
measurement when the store retires, then sends one decimal line, e.g.:

  RESULT=PASS,CYCLES=27,RETIRED=6,LOADS=1,STORES=2,WAITS=0

CYCLES counts enabled core clock edges, including memory waits, from the
first enabled fetch after reset through the marker store's WB edge. RETIRED
includes that final store. LOADS and STORES count accepted operations,
including marker and test-report stores. WAITS counts enabled requests with
ready low; it is zero here because ready is tied high. Counters are 64-bit
and wrap on overflow. Pauses and CPU_DIVIDER exclude disabled edges, so use
CPU_DIVIDER=1 and do not pause when calculating elapsed time as CYCLES /
100 MHz. Reset for another run.

After synthesis and implementation, inspect timing summary, worst setup
path, unconstrained paths, and utilization. The 10 ns constraint is a
target, not evidence that timing is met. Compare against the original using
the same part, clock, XDC, tool settings, and comparable board setup; a
different ROM image can affect optimization and resource results. Examine
whether the synthesized MulDiv is present. No synthesis or timing report
is supplied with this experiment. For CPI comparisons, run the same RV32I
image on both cores. Reporting/counter logic contributes to board resource
and timing results; inspect whether the worst path is actually in the core.
