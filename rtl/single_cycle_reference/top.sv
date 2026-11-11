/** Archived single-cycle CPU plus local instruction/data memories. */
module top #(
    parameter integer IMEM_DEPTH=1024,
    parameter integer DMEM_DEPTH=1024,
    parameter IMEM_FILE=""
) (input logic clk, reset);
    wire [31:0] pc, instruction, mem_addr, mem_write_data, mem_read_data;
    wire mem_read, mem_write;
    cpu u_cpu (.clk(clk),.reset(reset),.instruction(instruction),
        .mem_read_data(mem_read_data),.pc(pc),.mem_addr(mem_addr),
        .mem_write_data(mem_write_data),.mem_read(mem_read),.mem_write(mem_write));
    memory #(.IMEM_DEPTH(IMEM_DEPTH),.DMEM_DEPTH(DMEM_DEPTH),.IMEM_FILE(IMEM_FILE))
        u_memory (.clk(clk),.pc(pc),.addr(mem_addr),.write_data(mem_write_data),
        .mem_read(mem_read),.mem_write(mem_write),.instruction(instruction),.read_data(mem_read_data));
endmodule
