// RV32I/RV32M combinational arithmetic and logic unit.
module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result,
    output wire        zero,
    output reg         illegal_op
);
    always @* begin
        result = 32'b0;
        illegal_op = 1'b0;
        case (alu_op)
            4'd0: result = a + b;                                      // ADD
            4'd1: result = a - b;                                      // SUB
            4'd2: result = a & b;                                      // AND
            4'd3: result = a | b;                                      // OR
            4'd4: result = a ^ b;                                      // XOR
            4'd5: result = {31'b0, ($signed(a) < $signed(b))};          // SLT
            4'd6: result = {31'b0, (a < b)};                           // SLTU
            4'd7: result = a << b[4:0];                                // SLL
            4'd8: result = a >> b[4:0];                                // SRL
            4'd9: result = $signed(a) >>> b[4:0];                      // SRA
            default: illegal_op = 1'b1;
        endcase
    end
    assign zero = (result == 32'b0);
endmodule
