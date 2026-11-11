module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] write_data,
    input  wire        reg_write,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    reg [31:0] registers [0:31];

    wire [31:0] reg1_raw = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    wire [31:0] reg2_raw = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

    assign read_data1 = (reg_write && (rd != 5'b0) && (rs1 == rd)) ? write_data : reg1_raw;
    assign read_data2 = (reg_write && (rd != 5'b0) && (rs2 == rd)) ? write_data : reg2_raw;

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end else if (reg_write && (rd != 5'b0)) begin
            registers[rd] <= write_data;
        end
    end
endmodule
