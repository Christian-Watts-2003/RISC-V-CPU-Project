module decode_unit (
    input wire instr_valid, input wire [31:0] instruction,
    output reg legal, output wire [4:0] rs1, rs2, rd,
    output reg [3:0] alu_op, output reg [1:0] operand_a_sel,
    output reg operand_b_imm, output reg [2:0] imm_src,
    output reg is_branch, output reg [2:0] branch_type,
    output reg is_jump, is_jalr, mem_read, mem_write,
    output reg [1:0] mem_size, output reg load_unsigned, reg_write,
    output reg [1:0] wb_sel, exec_sel, output reg md_start,
    output reg [2:0] md_op
);
    localparam [3:0] ALU_ADD=4'd0, ALU_SUB=4'd1, ALU_AND=4'd2,
        ALU_OR=4'd3, ALU_XOR=4'd4, ALU_SLT=4'd5, ALU_SLTU=4'd6,
        ALU_SLL=4'd7, ALU_SRL=4'd8, ALU_SRA=4'd9;
    assign rs1=instruction[19:15]; assign rs2=instruction[24:20]; assign rd=instruction[11:7];
    always @* begin
        legal=0; alu_op=ALU_ADD; operand_a_sel=0; operand_b_imm=0;
        imm_src=0; is_branch=0; branch_type=0; is_jump=0; is_jalr=0;
        mem_read=0; mem_write=0; mem_size=2; load_unsigned=0;
        reg_write=0; wb_sel=0; exec_sel=0; md_start=0; md_op=0;
        if (instr_valid) case (instruction[6:0])
            7'b0110111: begin legal=1; reg_write=1; operand_a_sel=2; operand_b_imm=1; imm_src=3; end
            7'b0010111: begin legal=1; reg_write=1; operand_a_sel=1; operand_b_imm=1; imm_src=3; end
            7'b1101111: begin legal=1; reg_write=1; is_jump=1; operand_b_imm=1; imm_src=4; wb_sel=2; exec_sel=2; end
            7'b1100111: if (instruction[14:12]==0) begin legal=1; reg_write=1; is_jump=1; is_jalr=1; operand_b_imm=1; wb_sel=2; exec_sel=2; end
            7'b1100011: case (instruction[14:12])
                0,1,4,5,6,7: begin legal=1; is_branch=1; branch_type=instruction[14:12]; imm_src=2; end
                default: ;
            endcase
            7'b0000011: begin
                case (instruction[14:12])
                    0,4: begin legal=1; mem_size=0; end
                    1,5: begin legal=1; mem_size=1; end
                    2: begin legal=1; mem_size=2; end
                    default: ;
                endcase
                if (legal) begin operand_b_imm=1; mem_read=1; reg_write=1; wb_sel=1; load_unsigned=(instruction[14:12]==4 || instruction[14:12]==5); end
            end
            7'b0100011: begin
                case (instruction[14:12])
                    0: begin legal=1; mem_size=0; end
                    1: begin legal=1; mem_size=1; end
                    2: begin legal=1; mem_size=2; end
                    default: ;
                endcase
                if (legal) begin operand_b_imm=1; imm_src=1; mem_write=1; end
            end
            7'b0010011: begin
                case (instruction[14:12])
                    0: begin legal=1; alu_op=ALU_ADD; end
                    2: begin legal=1; alu_op=ALU_SLT; end
                    3: begin legal=1; alu_op=ALU_SLTU; end
                    4: begin legal=1; alu_op=ALU_XOR; end
                    6: begin legal=1; alu_op=ALU_OR; end
                    7: begin legal=1; alu_op=ALU_AND; end
                    1: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_SLL; end
                    5: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_SRL; end else if (instruction[31:25]==7'b0100000) begin legal=1; alu_op=ALU_SRA; end
                    default: ;
                endcase
                if (legal) begin reg_write=1; operand_b_imm=1; end
            end
            7'b0110011: begin
                if (instruction[31:25]==1) begin legal=1; reg_write=1; md_start=1; md_op=instruction[14:12]; wb_sel=3; exec_sel=1; end
                else begin
                    case (instruction[14:12])
                        0: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_ADD; end else if (instruction[31:25]==7'b0100000) begin legal=1; alu_op=ALU_SUB; end
                        1: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_SLL; end
                        2: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_SLT; end
                        3: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_SLTU; end
                        4: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_XOR; end
                        5: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_SRL; end else if (instruction[31:25]==7'b0100000) begin legal=1; alu_op=ALU_SRA; end
                        6: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_OR; end
                        7: if (instruction[31:25]==0) begin legal=1; alu_op=ALU_AND; end
                        default: ;
                    endcase
                    if (legal) reg_write=1;
                end
            end
            default: ;
        endcase
        if (!legal) begin
            alu_op=ALU_ADD; operand_a_sel=0; operand_b_imm=0; imm_src=0;
            is_branch=0; branch_type=0; is_jump=0; is_jalr=0;
            mem_read=0; mem_write=0; mem_size=2; load_unsigned=0;
            reg_write=0; wb_sel=0; exec_sel=0; md_start=0; md_op=0;
        end
    end
endmodule
