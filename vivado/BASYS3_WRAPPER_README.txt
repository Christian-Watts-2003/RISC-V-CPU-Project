BASYS3 SINGLE-CYCLE WRAPPER

Top module
----------
basys3_single_cycle_top

Sources
-------
- single_cycle_Innovus.v
- vivado/basys3_single_cycle_top.v
- vivado/uart_tx.v
- vivado/performance_uart_reporter.v
- vivado/basys3_single_cycle.xdc

Configuration
-------------
DEBUG_MODE = 1 (default)
  The CPU advances on a slow clock-enable pulse controlled by DEBUG_DIV_BITS.
  The seven-segment display and LEDs show the value selected by sw[3:0]:

    0: PC
    1: instruction
    2: data address
    3: store data
    4: cycle count
    5: instruction count
    6: store count
    7: load data

DEBUG_MODE = 0
  The CPU advances every 100 MHz clock cycle. The counters provide a simple
  performance run. Set PERF_LIMIT to a nonzero value to stop after that many
  CPU cycles; leave it at zero for continuous execution.
  UART_BAUD_DIV defaults to 868 for 115200 baud from the 100 MHz board clock.

The display shows the low 16 bits of the selected 32-bit value. LEDs also
show the low 16 bits. The center button is the synchronous CPU reset input.

The wrapper uses an FPGA-initialized ROM through IMEM_FILE and an inferred
data RAM. `$readmemh` initialization is appropriate for Vivado FPGA use and
should not be used in the Innovus source.

The wrapper intentionally uses a clock enable rather than a derived or gated
clock. This keeps debug and performance modes on the same 100 MHz clock.

UART performance summary
------------------------
In performance mode, set PERF_LIMIT to a nonzero cycle count. When the run
finishes, the wrapper transmits one line through uart_tx at 115200 baud,
8 data bits, no parity, and one stop bit:

    CYCLES=000012A4 PC=00000080 STORES=00000008

Connect the Basys3 USB cable, identify its virtual COM port, and configure
Tera Term for 115200-8-N-1 with no flow control. The UART output is on the
Basys3 USB-RS232 transmit pin.
