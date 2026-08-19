/**
 * Register File
 * 32 x 32-bit general-purpose registers with 2 read ports and 1 write port.
 */

module regfile (
    input  logic        clk,
    input  logic [4:0]  rs1, rs2, rd,
    input  logic [31:0] write_data,
    input  logic        reg_write,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] registers [32];

    assign read_data1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

    always_ff @(posedge clk) begin
        if (reg_write && (rd != 5'b0))
            registers[rd] <= write_data;
    end

    initial begin
        for (int i = 0; i < 32; i++)
            registers[i] = 32'b0;
    end

endmodule
