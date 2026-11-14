// Flat decoder for the documented single-cycle RV32IM instruction subset.
// Unsupported and illegal encodings are NOPs: legal=0 and no side effects.
module controller (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        legal,
    output reg [3:0]  alu_op,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg [2:0]  imm_src,
    output reg [1:0]  operand_a_sel, // 0=rs1, 1=PC, 2=zero
    output reg        alu_src,       // 1=immediate, 0=rs2
    output reg        branch,
    output reg [2:0]  branch_type,
    output reg        jump,
    output reg        jalr,
    output reg [1:0]  mem_size,      // 0=byte, 1=halfword, 2=word
    output reg        load_unsigned,
    output reg        is_muldiv,
    output reg [2:0]  muldiv_op
);
    localparam [3:0] ADD=0, SUB=1, AND_OP=2, OR_OP=3, XOR_OP=4,
                     SLT=5, SLTU=6, SLL=7, SRL=8, SRA=9;

    always @* begin
        legal=0; alu_op=ADD; reg_write=0; mem_read=0; mem_write=0;
        imm_src=0; operand_a_sel=0; alu_src=0; branch=0;
        branch_type=0; jump=0; jalr=0; mem_size=2; load_unsigned=0;
        is_muldiv=0; muldiv_op=0;

        case (opcode)
            7'b0110111: begin // LUI
                legal=1; reg_write=1; operand_a_sel=2; alu_src=1; imm_src=3;
            end
            7'b0010111: begin // AUIPC
                legal=1; reg_write=1; operand_a_sel=1; alu_src=1; imm_src=3;
            end
            7'b1101111: begin // JAL
                legal=1; reg_write=1; jump=1; imm_src=4;
            end
            7'b1100111: if (funct3==3'b000) begin // JALR
                legal=1; reg_write=1; jump=1; jalr=1; alu_src=1; imm_src=0;
            end
            7'b1100011: begin // Conditional branches
                case (funct3)
                    3'b000,3'b001,3'b100,3'b101,3'b110,3'b111: begin
                        legal=1; branch=1; branch_type=funct3; imm_src=2;
                    end
                    default: ;
                endcase
            end
            7'b0000011: begin // LB/LH/LW/LBU/LHU
                case (funct3)
                    3'b000: begin legal=1; mem_size=0; end
                    3'b001: begin legal=1; mem_size=1; end
                    3'b010: begin legal=1; mem_size=2; end
                    3'b100: begin legal=1; mem_size=0; load_unsigned=1; end
                    3'b101: begin legal=1; mem_size=1; load_unsigned=1; end
                    default: ;
                endcase
                if (legal) begin
                    reg_write=1; mem_read=1; alu_src=1; imm_src=0;
                end
            end
            7'b0100011: begin // SB/SH/SW
                case (funct3)
                    3'b000: begin legal=1; mem_size=0; end
                    3'b001: begin legal=1; mem_size=1; end
                    3'b010: begin legal=1; mem_size=2; end
                    default: ;
                endcase
                if (legal) begin mem_write=1; alu_src=1; imm_src=1; end
            end
            7'b0010011: begin // OP-IMM
                case (funct3)
                    3'b000: begin legal=1; alu_op=ADD; end // ADDI
                    3'b010: begin legal=1; alu_op=SLT; end // SLTI
                    3'b011: begin legal=1; alu_op=SLTU; end // SLTIU
                    3'b100: begin legal=1; alu_op=XOR_OP; end
                    3'b110: begin legal=1; alu_op=OR_OP; end
                    3'b111: begin legal=1; alu_op=AND_OP; end
                    3'b001: if (funct7==7'b0000000) begin legal=1; alu_op=SLL; end
                    3'b101: begin
                        if (funct7==7'b0000000) begin legal=1; alu_op=SRL; end
                        else if (funct7==7'b0100000) begin legal=1; alu_op=SRA; end
                    end
                    default: ;
                endcase
                if (legal) begin reg_write=1; alu_src=1; imm_src=0; end
            end
            7'b0110011: begin // OP and RV32M
                if (funct7==7'b0000001) begin
                    legal=0; reg_write=0; is_muldiv=0; muldiv_op=funct3;
                end else begin
                    case (funct3)
                        3'b000: begin
                            if (funct7==7'b0000000) begin legal=1; alu_op=ADD; end
                            else if (funct7==7'b0100000) begin legal=1; alu_op=SUB; end
                        end
                        3'b001: if (funct7==7'b0000000) begin legal=1; alu_op=SLL; end
                        3'b010: if (funct7==7'b0000000) begin legal=1; alu_op=SLT; end
                        3'b011: if (funct7==7'b0000000) begin legal=1; alu_op=SLTU; end
                        3'b100: if (funct7==7'b0000000) begin legal=1; alu_op=XOR_OP; end
                        3'b101: begin
                            if (funct7==7'b0000000) begin legal=1; alu_op=SRL; end
                            else if (funct7==7'b0100000) begin legal=1; alu_op=SRA; end
                        end
                        3'b110: if (funct7==7'b0000000) begin legal=1; alu_op=OR_OP; end
                        3'b111: if (funct7==7'b0000000) begin legal=1; alu_op=AND_OP; end
                        default: ;
                    endcase
                    if (legal) reg_write=1;
                end
            end
            // FENCE, SYSTEM, and all other unsupported encodings are NOPs.
            default: ;
        endcase
    end
endmodule
