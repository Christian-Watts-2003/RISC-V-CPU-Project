/**
 * Control Unit
 * Decodes RV32I instructions and generates control signals
 * for the datapath.
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
    output logic       alu_src   // 0 = rs2, 1 = immediate
);

    // Safe defaults (prevents latches)
    always_comb begin
        alu_op     = 4'b0000;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        imm_src    = 3'b000;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_src    = 1'b0;

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_src   = 1'b0; // use rs2
                // alu_op set below
            end

            7'b0010011: begin // I-type (immediate)
                reg_write = 1'b1;
                alu_src   = 1'b1; // use immediate
                imm_src   = 3'b000;
            end

            7'b0000011: begin // Load
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src   = 1'b1;
                imm_src   = 3'b000;
            end

            7'b0100011: begin // Store
                mem_write = 1'b1;
                alu_src   = 1'b1;
                imm_src   = 3'b001;
            end

            7'b1100011: begin // Branch
                branch    = 1'b1;
                alu_src   = 1'b0;
                imm_src   = 3'b010;
            end

            7'b1101111: begin // JAL
                jump      = 1'b1;
                reg_write = 1'b1;
                imm_src   = 3'b100;
            end

            7'b1100111: begin // JALR
                jump      = 1'b1;
                reg_write = 1'b1;
                alu_src   = 1'b1;
                imm_src   = 3'b000;
            end

            7'b0110111: begin // LUI
                reg_write = 1'b1;
                imm_src   = 3'b011;
            end

            7'b0010111: begin // AUIPC
                reg_write = 1'b1;
                imm_src   = 3'b011;
            end

            default: begin
                // Illegal instruction — all signals stay at default (0)
            end
        endcase

        // ALU operation decoding (R-type and I-type)
        if (opcode == 7'b0110011 || opcode == 7'b0010011) begin
            case (funct3)
                3'b000: alu_op = (opcode == 7'b0110011 && funct7[5]) ? 4'b0001 : 4'b0000; // SUB or ADD
                3'b001: alu_op = 4'b0110; // SLL
                3'b010: alu_op = 4'b0101; // SLT
                3'b011: alu_op = 4'b0101; // SLTU (placeholder for now)
                3'b100: alu_op = 4'b0100; // XOR
                3'b101: alu_op = (funct7[5]) ? 4'b1000 : 4'b0111; // SRA / SRL
                3'b110: alu_op = 4'b0011; // OR
                3'b111: alu_op = 4'b0010; // AND
                default: alu_op = 4'b0000;
            endcase
        end
    end

endmodule
