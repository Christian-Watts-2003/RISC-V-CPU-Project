/**
 * Register File
 * 32 x 32-bit general-purpose registers with 2 read ports and 1 write port.
 */

module regfile (
    input logic clk,                    // Clock
    input logic [4:0] rs1, rs2, rd,     // Address inputs
    input logic [31:0] write_data,      // Data to write
    input logic reg_write,              // Write enable
    output logic [31:0] read_data1,     // Data from rs1
    output logic [31:0] read_data2      // Data from rs2
);

    // 32 x 32-bit register array
    logic [31:0] registers [32];

    // ASYNCHRONOUS READ
    // If reading x0, always return 0
    // Otherwise, return the value in the register
    assign read_data1 = (rs1 == 5'b0) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2 == 5'b0) ? 32'b0 : registers[rs2];

    // SYNCHRONOUS WRITE
    // On rising clock edge:
    // If reg_write is high AND rd is not x0
    // Then write the value to registers[rd]
    always_ff @(posedge clk) begin
        if (reg_write && (rd != 5'b0)) begin
            registers[rd] <= write_data;
        end
    end

    // Set all registers to 0 at simulation start
    initial begin
        for (int i = 0; i < 32; i++) begin
            registers[i] = 32'b0;
        end
    end

endmodule
