/**
 * RV32M Multiply / Divide Unit
 * Separate from the main ALU for cleanliness
 */

module muldiv (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    input  logic [2:0]  muldiv_op,
    input  logic [31:0] a, b,
    output logic [31:0] result,
    output logic        valid
);

    logic signed [63:0] prod_signed;
    logic        [63:0] prod_unsigned;

    always_comb begin
        prod_signed   = $signed(a) * $signed(b);
        prod_unsigned = a * b;

        case (muldiv_op)
            // Multiplication
            3'b000: result = prod_signed[31:0];                    // MUL (low 32 bits)
            3'b001: result = prod_signed[63:32];                   // MULH (high 32 bits)
            3'b010: result = ($signed(a) * $unsigned(b))[63:32];   // MULHSU
            3'b011: result = prod_unsigned[63:32];                 // MULHU (high 32 bits)

            // Division
            3'b100: begin // DIV (signed)
                if (b == 0)
                    result = 32'hFFFFFFFF;
                else if (a == 32'h80000000 && b == 32'hFFFFFFFF)
                    result = 32'h80000000;   // overflow case
                else
                    result = $signed(a) / $signed(b);
            end

            3'b101: result = (b == 0) ? 32'hFFFFFFFF : a / b;      // DIVU

            // Remainder
            3'b110: begin // REM (signed)
                if (b == 0)
                    result = a;
                else if (a == 32'h80000000 && b == 32'hFFFFFFFF)
                    result = 32'b0;
                else
                    result = $signed(a) % $signed(b);
            end

            3'b111: result = (b == 0) ? a : a % b;                 // REMU

            default: result = 32'b0;
        endcase
    end

    assign valid = start;   // Placeholder

endmodule
