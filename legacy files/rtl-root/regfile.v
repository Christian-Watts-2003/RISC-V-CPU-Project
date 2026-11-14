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

    // The specification does not require a dedicated reset for the register file.
    // x0 is hardwired to zero, and the other registers start from zero in the
    // simulator by the initialization block below.
    initial begin
        for (i = 0; i < 32; i = i + 1)
            registers[i] = 32'b0;
    end

    assign read_data1 = (reg_write && (rd != 5'b0) && (rs1 == rd)) ? write_data :
                       ((rs1 == 5'b0) ? 32'b0 : registers[rs1]);
    assign read_data2 = (reg_write && (rd != 5'b0) && (rs2 == rd)) ? write_data :
                       ((rs2 == 5'b0) ? 32'b0 : registers[rs2]);

    always @(posedge clk) begin
        if (reg_write && (rd != 5'b0))
            registers[rd] <= write_data;
    end
endmodule
