/**
 * Archived single-cycle controller, retained for reference.
 * See rtl/controller.sv for the pipelined implementation when it is added.
 */
module controller (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output logic [3:0] alu_op,
    output logic reg_write, mem_read, mem_write,
    output logic [2:0] imm_src,
    output logic branch, jump, alu_src, is_muldiv,
    output logic [2:0] muldiv_op
);
    localparam logic [6:0] OP_REG=7'b0110011, OP_IMM=7'b0010011,
        OP_LOAD=7'b0000011, OP_STORE=7'b0100011, OP_BRANCH=7'b1100011,
        OP_JAL=7'b1101111, OP_JALR=7'b1100111, OP_LUI=7'b0110111,
        OP_AUIPC=7'b0010111;
    localparam logic [6:0] FUNCT7_BASE=7'b0000000, FUNCT7_SUB=7'b0100000,
        FUNCT7_M=7'b0000001;
    localparam logic [3:0] ALU_ADD=4'b0000, ALU_SUB=4'b0001,
        ALU_AND=4'b0010, ALU_OR=4'b0011, ALU_XOR=4'b0100,
        ALU_SLT=4'b0101, ALU_SLL=4'b0110, ALU_SRL=4'b0111,
        ALU_SRA=4'b1000, ALU_SLTU=4'b1001;
    always_comb begin
        alu_op=ALU_ADD; reg_write=0; mem_read=0; mem_write=0;
        imm_src=0; branch=0; jump=0; alu_src=0; is_muldiv=0; muldiv_op=0;
        case (opcode)
            OP_REG: begin
                if (funct7==FUNCT7_M) begin
                    reg_write=1; is_muldiv=1; muldiv_op=funct3;
                    case (funct3)
                        0: alu_op=4'b1001; 1: alu_op=4'b1010;
                        2: alu_op=4'b1011; 3: alu_op=4'b1100;
                        4: alu_op=4'b1101; 5: alu_op=4'b1110;
                        6: alu_op=4'b1111; 7: alu_op=ALU_ADD;
                    endcase
                end else case (funct3)
                    0: if (funct7==FUNCT7_BASE) begin alu_op=ALU_ADD; reg_write=1; end
                       else if (funct7==FUNCT7_SUB) begin alu_op=ALU_SUB; reg_write=1; end
                    1: if (funct7==FUNCT7_BASE) begin alu_op=ALU_SLL; reg_write=1; end
                    2: if (funct7==FUNCT7_BASE) begin alu_op=ALU_SLT; reg_write=1; end
                    3: if (funct7==FUNCT7_BASE) begin alu_op=ALU_SLTU; reg_write=1; end
                    4: if (funct7==FUNCT7_BASE) begin alu_op=ALU_XOR; reg_write=1; end
                    5: if (funct7==FUNCT7_BASE) begin alu_op=ALU_SRL; reg_write=1; end
                       else if (funct7==FUNCT7_SUB) begin alu_op=ALU_SRA; reg_write=1; end
                    6: if (funct7==FUNCT7_BASE) begin alu_op=ALU_OR; reg_write=1; end
                    7: if (funct7==FUNCT7_BASE) begin alu_op=ALU_AND; reg_write=1; end
                endcase
            end
            OP_IMM: begin
                case (funct3)
                    0: begin alu_op=ALU_ADD; reg_write=1; end
                    2: begin alu_op=ALU_SLT; reg_write=1; end
                    3: begin alu_op=ALU_SLTU; reg_write=1; end
                    4: begin alu_op=ALU_XOR; reg_write=1; end
                    6: begin alu_op=ALU_OR; reg_write=1; end
                    7: begin alu_op=ALU_AND; reg_write=1; end
                    1: if (funct7==FUNCT7_BASE) begin alu_op=ALU_SLL; reg_write=1; end
                    5: if (funct7==FUNCT7_BASE) begin alu_op=ALU_SRL; reg_write=1; end
                       else if (funct7==FUNCT7_SUB) begin alu_op=ALU_SRA; reg_write=1; end
                endcase
                if (reg_write) begin alu_src=1; imm_src=0; end
            end
            OP_LOAD: if (funct3==2) begin reg_write=1; mem_read=1; alu_src=1; end
            OP_STORE: if (funct3==2) begin mem_write=1; alu_src=1; imm_src=1; end
            OP_BRANCH: if (funct3==0) begin branch=1; imm_src=2; alu_op=ALU_SUB; end
            OP_JAL: begin jump=1; reg_write=1; imm_src=4; end
            OP_JALR: if (funct3==0) begin jump=1; reg_write=1; alu_src=1; end
            OP_LUI: begin reg_write=1; imm_src=3; end
            OP_AUIPC: begin reg_write=1; imm_src=3; end
        endcase
    end
endmodule
