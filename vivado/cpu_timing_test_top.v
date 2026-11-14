// Minimal CPU-only timing wrapper.
//
// Instruction and load data are top-level inputs so Vivado cannot infer
// asynchronous ROM/RAM or optimize the CPU around constant memory contents.
// This top intentionally excludes the Basys3 ROM, RAM, display, counters,
// and UART logic.
module cpu_timing_test_top (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction,
    input  wire [31:0] mem_read_data,
    output wire [31:0] pc,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire [3:0]  mem_write_strobe,
    output wire        mem_read,
    output wire        mem_write
);
    cpu u_cpu (
        .clk(clk),
        .reset(reset),
        .enable(1'b1),
        .instruction(instruction),
        .mem_read_data(mem_read_data),
        .pc(pc),
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data),
        .mem_write_strobe(mem_write_strobe),
        .mem_read(mem_read),
        .mem_write(mem_write)
    );
endmodule
