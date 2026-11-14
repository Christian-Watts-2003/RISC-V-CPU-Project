/**
 * Simple combinational-read instruction ROM and data RAM.
 * Addresses are byte addresses; memory words are indexed by address[31:2].
 */
module memory #(
    parameter integer IMEM_DEPTH = 1024,
    parameter integer DMEM_DEPTH = 1024,
    parameter         IMEM_FILE  = ""
) (
    input  logic        clk,
    input  logic [31:0] pc,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    input  logic        mem_read,
    input  logic        mem_write,

    output logic [31:0] instruction,
    output logic [31:0] read_data
);

    logic [31:0] imem [0:IMEM_DEPTH-1];
    logic [31:0] dmem [0:DMEM_DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < IMEM_DEPTH; i = i + 1)
            imem[i] = 32'b0;
        for (i = 0; i < DMEM_DEPTH; i = i + 1)
            dmem[i] = 32'b0;
        if (IMEM_FILE != "")
            $readmemh(IMEM_FILE, imem);
    end

    always_comb begin
        if ((pc[1:0] == 2'b00) && ((pc >> 2) < IMEM_DEPTH))
            instruction = imem[pc[31:2]];
        else
            instruction = 32'b0;

        if (mem_read && (addr[1:0] == 2'b00) && ((addr >> 2) < DMEM_DEPTH))
            read_data = dmem[addr[31:2]];
        else
            read_data = 32'b0;
    end

    always_ff @(posedge clk) begin
        if (mem_write && (addr[1:0] == 2'b00) && ((addr >> 2) < DMEM_DEPTH))
            dmem[addr[31:2]] <= write_data;
    end

endmodule
