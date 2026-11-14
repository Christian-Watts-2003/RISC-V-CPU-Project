/**
 * Control Unit
 * Decodes the supported RV32I/RV32M instruction subset.
 *
 * Supported encodings:
 * - RV32I register-register and immediate ALU operations
 * - LW/SW, BEQ, JAL, JALR, LUI, and AUIPC
 * - RV32M operations
 *
 * FENCE, SYSTEM (including ECALL/EBREAK), other load/store widths, and
 * branch conditions other than BEQ are intentionally unsupported. Unsupported
 * or illegal encodings leave all side-effect controls deasserted.
 */
module controller (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic [3:0] alu_op,
    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic [2:0] imm_src,
    output logic       branch,
    output logic       jump,
    output logic       alu_src,
    output logic       is_muldiv,
    output logic [2:0] muldiv_op
);

    localparam logic [6:0] OP_REG    = 7'b0110011;
    localparam logic [6:0] OP_IMM    = 7'b0010011;
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;

    localparam logic [6:0] FUNCT7_BASE = 7'b0000000;
    localparam logic [6:0] FUNCT7_SUB  = 7'b0100000;
    localparam logic [6:0] FUNCT7_M    = 7'b0000001;

    // ALU operation encodings used by alu.sv.
    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b0001;
    localparam logic [3:0] ALU_AND  = 4'b0010;
    localparam logic [3:0] ALU_OR   = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_SLT  = 4'b0101;
    localparam logic [3:0] ALU_SLL  = 4'b0110;
    localparam logic [3:0] ALU_SRL  = 4'b0111;
    localparam logic [3:0] ALU_SRA  = 4'b1000;
    localparam logic [3:0] ALU_SLTU = 4'b1001;

    always_comb begin
        // Safe, side-effect-free defaults also reject unsupported encodings.
        alu_op     = ALU_ADD;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        imm_src    = 3'b000;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_src    = 1'b0;
        is_muldiv  = 1'b0;
        muldiv_op  = 3'b000;

        case (opcode)
            OP_REG: begin
                if (funct7 == FUNCT7_M) begin
                    // The M extension is legal only with the R-type opcode.
                    reg_write  = 1'b1;
                    is_muldiv  = 1'b1;
                    muldiv_op  = funct3;
                    case (funct3)
                        3'b000: alu_op = 4'b1001; // MUL
                        3'b001: alu_op = 4'b1010; // MULH
                        3'b010: alu_op = 4'b1011; // MULHSU
                        3'b011: alu_op = 4'b1100; // MULHU
                        3'b100: alu_op = 4'b1101; // DIV
                        3'b101: alu_op = 4'b1110; // DIVU
                        3'b110: alu_op = 4'b1111; // REM
                        3'b111: alu_op = 4'b0000; // REMU
                        default: begin
                            reg_write = 1'b0;
                            is_muldiv = 1'b0;
                            muldiv_op = 3'b000;
                        end
                    endcase
                end else begin
                    case (funct3)
                        3'b000: begin // ADD / SUB
                            if (funct7 == FUNCT7_BASE) begin
                                alu_op = ALU_ADD;
                                reg_write = 1'b1;
                            end else if (funct7 == FUNCT7_SUB) begin
                                alu_op = ALU_SUB;
                                reg_write = 1'b1;
                            end
                        end
                        3'b001: if (funct7 == FUNCT7_BASE) begin
                            alu_op = ALU_SLL;
                            reg_write = 1'b1;
                        end
                        3'b010: if (funct7 == FUNCT7_BASE) begin
                            alu_op = ALU_SLT;
                            reg_write = 1'b1;
                        end
                        3'b011: if (funct7 == FUNCT7_BASE) begin
                            alu_op = ALU_SLTU;
                            reg_write = 1'b1;
                        end
                        3'b100: if (funct7 == FUNCT7_BASE) begin
                            alu_op = ALU_XOR;
                            reg_write = 1'b1;
                        end
                        3'b101: begin // SRL / SRA
                            if (funct7 == FUNCT7_BASE) begin
                                alu_op = ALU_SRL;
                                reg_write = 1'b1;
                            end else if (funct7 == FUNCT7_SUB) begin
                                alu_op = ALU_SRA;
                                reg_write = 1'b1;
                            end
                        end
                        3'b110: if (funct7 == FUNCT7_BASE) begin
                            alu_op = ALU_OR;
                            reg_write = 1'b1;
                        end
                        3'b111: if (funct7 == FUNCT7_BASE) begin
                            alu_op = ALU_AND;
                            reg_write = 1'b1;
                        end
                        default: ;
                    endcase
                end
            end

            OP_IMM: begin
                // Immediate ALU operations use I-type immediate generation.
                case (funct3)
                    3'b000: begin alu_op = ALU_ADD; reg_write = 1'b1; end // ADDI
                    3'b010: begin alu_op = ALU_SLT; reg_write = 1'b1; end // SLTI
                    3'b011: begin alu_op = ALU_SLTU; reg_write = 1'b1; end // SLTIU
                    3'b100: begin alu_op = ALU_XOR; reg_write = 1'b1; end // XORI
                    3'b110: begin alu_op = ALU_OR;  reg_write = 1'b1; end // ORI
                    3'b111: begin alu_op = ALU_AND; reg_write = 1'b1; end // ANDI
                    3'b001: if (funct7 == FUNCT7_BASE) begin // SLLI
                        alu_op = ALU_SLL;
                        reg_write = 1'b1;
                    end
                    3'b101: begin // SRLI / SRAI
                        if (funct7 == FUNCT7_BASE) begin
                            alu_op = ALU_SRL;
                            reg_write = 1'b1;
                        end else if (funct7 == FUNCT7_SUB) begin
                            alu_op = ALU_SRA;
                            reg_write = 1'b1;
                        end
                    end
                    default: ;
                endcase
                if (reg_write) begin
                    alu_src = 1'b1;
                    imm_src = 3'b000;
                end
            end

            OP_LOAD: if (funct3 == 3'b010) begin // LW only
                alu_op = ALU_ADD;
                reg_write = 1'b1;
                mem_read = 1'b1;
                alu_src = 1'b1;
                imm_src = 3'b000;
            end

            OP_STORE: if (funct3 == 3'b010) begin // SW only
                alu_op = ALU_ADD;
                mem_write = 1'b1;
                alu_src = 1'b1;
                imm_src = 3'b001;
            end

            OP_BRANCH: if (funct3 == 3'b000) begin // BEQ only
                alu_op = ALU_SUB;
                branch = 1'b1;
                imm_src = 3'b010;
            end

            OP_JAL: begin
                reg_write = 1'b1;
                jump = 1'b1;
                imm_src = 3'b100;
            end

            OP_JALR: if (funct3 == 3'b000) begin
                reg_write = 1'b1;
                jump = 1'b1;
                alu_src = 1'b1;
                imm_src = 3'b000;
            end

            OP_LUI: begin
                reg_write = 1'b1;
                imm_src = 3'b011;
            end

            OP_AUIPC: begin
                reg_write = 1'b1;
                imm_src = 3'b011;
            end

            // FENCE, SYSTEM (ECALL/EBREAK), and unrecognized encodings are
            // deliberately unsupported and retain side-effect-free defaults.
            default: ;
        endcase
    end
endmodule
