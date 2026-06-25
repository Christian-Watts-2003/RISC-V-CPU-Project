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
);

  logic [31:0] sub_result;
  logic overflow;

  always_comb begin
    case (alu_op)
      4'b0000: result = a + b; //ADD
      4'b0001: result = a - b; //SUB
      4'b0010: result = a & b; //AND
      4'b0011: result = a | b; //OR
      4'b0100: result = a ^ b; //XOR
      4'b0101: begin
        sub_result = a - b;
        overflow = (a[31] != b[31]) && (a[31] != sub_result[31]);
        result = {{31{1'b0}}, sub_result[31] ^ overflow};
      end
            4'b0110: result = a << b[4:0]; // SLL
            4'b0111: result = a >> b[4:0]; // SRL
            4'b1000: result = $signed(a) >>> b[4:0]; // SRA
            default: result = 32'b0;
        endcase
    end
  
  assign zero = (result == 32'b0); //Zero flag
  
endmodule
