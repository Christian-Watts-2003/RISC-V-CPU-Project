// Arithmetic Logic Unit (ALU)

module alu (
    input  logic [31:0] a, b,
    input  logic [3:0]  alu_op,
    output logic [31:0] result,
    output logic        zero,
    output logic        illegal_op
);

    always_comb begin
        // Set safe defaults so every output has a value for every operation.
        illegal_op = 1'b0;
        result     = 32'b0;

        case (alu_op)
            4'b0000: result = a + b;                    // ADD
            4'b0001: result = a - b;                    // SUB
            4'b0010: result = a & b;                    // AND
            4'b0011: result = a | b;                    // OR
            4'b0100: result = a ^ b;                    // XOR
            4'b0101: result = {31'b0, ($signed(a) < $signed(b))}; // SLT
            4'b0110: result = a << b[4:0];              // SLL
            4'b0111: result = a >> b[4:0];              // SRL
            4'b1000: result = $signed(a) >>> b[4:0];    // SRA
            4'b1001: result = {31'b0, (a < b)};         // SLTU
            default: begin
                // An unsupported operation returns zero and raises a flag.
                result     = 32'b0;
                illegal_op = 1'b1;
            end
        endcase
    end

    // The branch logic can use this flag to check whether the result is zero.
    assign zero = (result == 32'b0);

endmodule
