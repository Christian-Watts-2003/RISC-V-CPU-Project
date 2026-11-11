// Standalone single-cycle CPU + behavioral memories.
module top #(
    parameter integer IMEM_DEPTH=1024,
    parameter integer DMEM_DEPTH=1024,
    parameter IMEM_FILE=""
) (
    input wire clk,
    input wire reset
);
    wire [31:0] pc,instruction,mem_addr,write_data,read_data;
    wire [3:0] write_strobe;
    wire mem_read,mem_write;
    cpu u_cpu (.clk(clk),.reset(reset),.instruction(instruction),.mem_read_data(read_data),
        .pc(pc),.mem_addr(mem_addr),.mem_write_data(write_data),
        .mem_write_strobe(write_strobe),.mem_read(mem_read),.mem_write(mem_write));
    memory #(.IMEM_DEPTH(IMEM_DEPTH),.DMEM_DEPTH(DMEM_DEPTH),.IMEM_FILE(IMEM_FILE)) u_memory (
        .clk(clk),.pc(pc),.addr(mem_addr),.write_data(write_data),
        .write_strobe(write_strobe),.mem_read(mem_read),.mem_write(mem_write),
        .instruction(instruction),.read_data(read_data));
endmodule
