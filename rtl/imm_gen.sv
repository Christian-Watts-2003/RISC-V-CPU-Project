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
    input logic [31:0] instruction,    // 32-bit instruction
    input logic [2:0] imm_src,         // Select
  output logic [31:0] imm_value      // Sign-extention
);

    // 000 (0) = I-type
    // 001 (1) = S-type
    // 010 (2) = B-type
    // 011 (3) = U-type
    // 100 (4) = J-type

    always_comb begin
        case (imm_src)
            
            // I-Type: ADDI, SLTI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, LW, LH, LB
            3'b000: begin
                imm_value = {{20{instruction[31]}}, instruction[31:20]};
            end
            
            // S-Type: SW, SH, SB
            3'b001: begin
                imm_value = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end
            
            // B-Type: BEQ, BNE, BLT, BGE, BLTU, BGEU
            3'b010: begin
                imm_value = {{20{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end
            
            // U-Type: LUI, AUIPC
            3'b011: begin
                imm_value = {instruction[31:12], 12'b0};
            end
            
            // J-Type: JAL
            3'b100: begin
                imm_value = {{12{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end
            
            // Default (R-Type)
            default: begin
                imm_value = 32'b0;
            end
            
        endcase
    end

endmodule
