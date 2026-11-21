// Combinational instruction read and synchronous byte-write data RAM.
// This behavioral memory is intended for simulation/FPGA inference; ASIC flows
// should replace it with a technology-specific ROM/RAM macro as appropriate.
module memory #(
    parameter integer IMEM_DEPTH=1024,
    parameter integer DMEM_DEPTH=1024,
    parameter IMEM_FILE=""
) (
    input  wire        clk,
    input  wire [31:0] pc,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    input  wire [3:0]  write_strobe,
    input  wire        mem_read,
    input  wire        mem_write,
    output reg  [31:0] instruction,
    output reg  [31:0] read_data
);
    reg [31:0] imem [0:IMEM_DEPTH-1];
    reg [31:0] dmem [0:DMEM_DEPTH-1];
    integer i;
    initial begin
        for (i=0;i<IMEM_DEPTH;i=i+1) imem[i]=32'b0;
        for (i=0;i<DMEM_DEPTH;i=i+1) dmem[i]=32'b0;
        if (IMEM_FILE!="") $readmemh(IMEM_FILE,imem);
    end
    always @* begin
        instruction=32'b0; read_data=32'b0;
        if (pc[1:0]==0 && pc[31:2]<IMEM_DEPTH) instruction=imem[pc[31:2]];
        if (mem_read && addr[31:2]<DMEM_DEPTH) read_data=dmem[addr[31:2]];
    end
    always @(posedge clk) begin
        if (mem_write && addr[31:2]<DMEM_DEPTH) begin
            if (write_strobe[0]) dmem[addr[31:2]][7:0] <= write_data[7:0];
            if (write_strobe[1]) dmem[addr[31:2]][15:8] <= write_data[15:8];
            if (write_strobe[2]) dmem[addr[31:2]][23:16] <= write_data[23:16];
            if (write_strobe[3]) dmem[addr[31:2]][31:24] <= write_data[31:24];
        end
    end
endmodule
