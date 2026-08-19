/**
 * Immediate Generator
 *
 * Input: 32-bit instruction word
 * Input: 3-bit format selector (which type of immediate?)
 * Output: 32-bit sign-extended immediate value
 * 
 * @author Christian Watts
 * @version 1.0
 */

module imm_gen (
    input  logic [31:0] instruction,
    input  logic [2:0]  imm_src,
    output logic [31:0] imm_value
);

    always_comb begin
        case (imm_src)
            3'b000: imm_value = {{20{instruction[31]}}, instruction[31:20]};                    // I-type
            3'b001: imm_value = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]}; // S-type
            3'b010: imm_value = {{20{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; // B-type
            3'b011: imm_value = {instruction[31:12], 12'b0};                                    // U-type
            3'b100: imm_value = {{12{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0}; // J-type
            default: imm_value = 32'b0;
        endcase
    end

endmodule
