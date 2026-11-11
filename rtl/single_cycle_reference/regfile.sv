/** Archived single-cycle register file. */
module regfile (
    input logic clk,
    input logic [4:0] rs1, rs2, rd,
    input logic [31:0] write_data,
    input logic reg_write,
    output wire [31:0] read_data1, read_data2
);
    reg [31:0] registers [0:31];
    assign read_data1=(rs1==0)?32'b0:registers[rs1];
    assign read_data2=(rs2==0)?32'b0:registers[rs2];
    always @(posedge clk) if (reg_write && rd!=0) registers[rd]<=write_data;
    integer i;
    initial for (i=0;i<32;i=i+1) registers[i]=0;
endmodule
