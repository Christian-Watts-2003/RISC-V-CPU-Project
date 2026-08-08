/**
 * RV32M Multiply / Divide Unit
 * Separate from the main ALU for cleanliness
 */

module muldiv (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,          // Asserted when is_muldiv == 1
    input  logic [2:0]  muldiv_op,
    input  logic [31:0] a, b,           // rs1 and rs2
    output logic [31:0] result,
    output logic        valid           // Result is ready
);

    // TODO: Implement actual multiply/divide logic here
    // For now, this is just a placeholder

    always_comb begin
        case (muldiv_op)
            3'b000: result = a * b;           // MUL (placeholder)
            3'b001: result = a * b;           // MULH (placeholder)
            3'b010: result = a * b;           // MULHSU
            3'b011: result = a * b;           // MULHU
            3'b100: result = a / b;           // DIV
            3'b101: result = a / b;           // DIVU
            3'b110: result = a % b;           // REM
            3'b111: result = a % b;           // REMU
            default: result = 32'b0;
        endcase
    end

    assign valid = start;   // Placeholder — real version will be multi-cycle

endmodule
