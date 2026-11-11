/** Archived simulation memory for the single-cycle CPU. */
module memory #(
    parameter integer IMEM_DEPTH=1024,
    parameter integer DMEM_DEPTH=1024,
    parameter IMEM_FILE=""
) (
    input logic clk,
    input logic [31:0] pc, addr, write_data,
    input logic mem_read, mem_write,
    output reg [31:0] instruction, read_data
);
    reg [31:0] imem [0:IMEM_DEPTH-1];
    reg [31:0] dmem [0:DMEM_DEPTH-1];
    integer i;
    initial begin
        for (i=0;i<IMEM_DEPTH;i=i+1) imem[i]=0;
        for (i=0;i<DMEM_DEPTH;i=i+1) dmem[i]=0;
        if (IMEM_FILE!="") $readmemh(IMEM_FILE,imem);
    end
    always @* begin
        if (pc[1:0]==0 && (pc>>2)<IMEM_DEPTH) instruction=imem[pc[31:2]];
        else instruction=0;
        if (mem_read && addr[1:0]==0 && (addr>>2)<DMEM_DEPTH) read_data=dmem[addr[31:2]];
        else read_data=0;
    end
    always @(posedge clk) begin
        if (mem_write && addr[1:0]==0 && (addr>>2)<DMEM_DEPTH)
            dmem[addr[31:2]]<=write_data;
    end
endmodule
