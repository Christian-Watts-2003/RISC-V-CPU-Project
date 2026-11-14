SINGLE-CYCLE INNOVUS RTL SOURCE

Source
------
single_cycle_Innovus.v

Top module
----------
single_cycle_Innovus

This is a unified CPU-only RTL source for Innovus compilation. It contains
the maintained single-cycle controller, datapath, ALU, branch unit, immediate
generator, LSU, multiply/divide unit, and register file in one Verilog source.

Instruction and data memories are external. The wrapper ports are:

  clk        rising-edge clock
  rst        synchronous active-high reset
  imem_rdata combinational instruction word
  imem_addr  instruction fetch address / PC
  dmem_rdata combinational aligned load word
  dmem_addr  data address
  dmem_wdata shifted store data
  dmem_wstrb byte write strobes
  dmem_re    load request
  dmem_we    store request

Compile the single source with `single_cycle_Innovus` as the top module. Do
not add the testbenches or the behavioral memory module to the Innovus RTL
source set.

The register file has no reset and must be initialized by the surrounding
system or by the program/test environment. The current single-cycle RV32M
implementation uses combinational multiplication and division, so those
operations are part of the synthesized critical path.
