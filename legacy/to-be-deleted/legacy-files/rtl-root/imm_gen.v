module imm_gen (
    input  wire [31:0] instruction,
    input  wire [2:0]  imm_src,
    output reg  [31:0] imm_value
);

    always @(*) begin
        case (imm_src)
            3'b000: imm_value = {{20{instruction[31]}}, instruction[31:20]};
            3'b001: imm_value = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            3'b010: imm_value = {{20{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            3'b011: imm_value = {instruction[31:12], 12'b0};
            3'b100: imm_value = {{12{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            default: imm_value = 32'b0;
        endcase
    end
endmodule
