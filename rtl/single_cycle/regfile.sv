// 32 x 32-bit register file, asynchronous reads and synchronous write.
module regfile (
    input  wire        clk,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    input  wire        reg_write,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);
    reg [31:0] registers [0:31];
    integer i;
    initial begin
        for (i=0;i<32;i=i+1) registers[i]=32'b0;
    end
    assign read_data1=(rs1==0) ? 32'b0 :
        ((reg_write && rd!=0 && rs1==rd) ? write_data : registers[rs1]);
    assign read_data2=(rs2==0) ? 32'b0 :
        ((reg_write && rd!=0 && rs2==rd) ? write_data : registers[rs2]);
    always @(posedge clk)
        if (reg_write && rd!=0) registers[rd] <= write_data;
endmodule
