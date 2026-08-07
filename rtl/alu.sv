/**
 * Arithmetic Logic Unit (ALU)
 * 
 * Supports basic RISC-V operations:
 * - Arithmetic: ADD, SUB, SLT
 * - Logical: AND, OR, XOR
 * - Shifts: SLL, SRL, SRA
 * 
 * @author Christian Watts
 * @version 1.0
 */

module alu (
  input logic [31:0] a, b,
  input logic [3:0] alu_op,
  output logic [31:0] result,
  output logic zero
  output logic        illegal_op // 1. Added debug output flag
);

  always_comb begin

    illegal_op = 1'b0; 
    
    case (alu_op)
      4'b0000: result = a + b; //ADD
      4'b0001: result = a - b; //SUB
      4'b0010: result = a & b; //AND
      4'b0011: result = a | b; //OR
      4'b0100: result = a ^ b; //XOR
      4'b0101: result = $signed(a) < $signed(b);   // SLT (signed)
      4'b0110: result = a << b[4:0]; // SLL
      4'b0111: result = a >> b[4:0]; // SRL
      4'b1000: result = $signed(a) >>> b[4:0]; // SRA
      default: result = 32'b0;

      default: begin 
        result     = 32'b0;
        illegal_op = 1'b1; 
      end
      
    endcase
  end
  
  assign zero = (result == 32'b0); //Zero flag
  
endmodule
