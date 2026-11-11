module decode_unit (
    input  wire        instr_valid,
    input  wire [31:0] instruction,
    output reg         legal,
    output wire [4:0]  rs1,
    output wire [4:0]  rs2,
    output wire [4:0]  rd,
    output reg  [3:0]  alu_op,
    output reg  [1:0]  operand_a_sel,
    output reg         operand_b_imm,
    output reg  [2:0]  imm_src,
    output reg         is_branch,
    output reg  [2:0]  branch_type,
    output reg         is_jump,
    output reg         is_jalr,
    output reg         mem_read,
    output reg         mem_write,
    output reg  [1:0]  mem_size,
    output reg         load_unsigned,
    output reg         reg_write,
    output reg  [1:0]  wb_sel,
    output reg  [1:0]  exec_sel,
    output reg         md_start,
    output reg  [2:0]  md_op
);

    localparam [3:0] ALU_ADD  = 4'd0;
    localparam [3:0] ALU_SUB  = 4'd1;
    localparam [3:0] ALU_AND  = 4'd2;
    localparam [3:0] ALU_OR   = 4'd3;
    localparam [3:0] ALU_XOR  = 4'd4;
    localparam [3:0] ALU_SLT  = 4'd5;
    localparam [3:0] ALU_SLTU = 4'd6;
    localparam [3:0] ALU_SLL  = 4'd7;
    localparam [3:0] ALU_SRL  = 4'd8;
    localparam [3:0] ALU_SRA  = 4'd9;

    // Operand A: 0=rs1, 1=PC, 2=zero. Operand B: rs2 or immediate.
    // Writeback: 0=ALU, 1=load, 2=link, 3=mul/div.
    // Execution select: 0=ALU, 1=mul/div, 2=link.
    // Memory size: 0=byte, 1=halfword, 2=word.
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd  = instruction[11:7];

    always @* begin
        legal          = 1'b0;
        alu_op         = ALU_ADD;
        operand_a_sel  = 2'd0;
        operand_b_imm  = 1'b0;
        imm_src        = 3'b000;
        is_branch      = 1'b0;
        branch_type    = 3'b000;
        is_jump        = 1'b0;
        is_jalr        = 1'b0;
        mem_read       = 1'b0;
        mem_write      = 1'b0;
        mem_size       = 2'd2;
        load_unsigned  = 1'b0;
        reg_write      = 1'b0;
        wb_sel         = 2'd0;
        exec_sel       = 2'd0;
        md_start       = 1'b0;
        md_op          = 3'b000;

        if (instr_valid) begin
            case (instruction[6:0])
                7'b0110111: begin // LUI
                    legal = 1'b1; reg_write = 1'b1; operand_a_sel = 2'd2;
                    operand_b_imm = 1'b1; imm_src = 3'b011;
                end
                7'b0010111: begin // AUIPC
                    legal = 1'b1; reg_write = 1'b1; operand_a_sel = 2'd1;
                    operand_b_imm = 1'b1; imm_src = 3'b011;
                end
                7'b1101111: begin // JAL
                    legal = 1'b1; reg_write = 1'b1; is_jump = 1'b1;
                    operand_b_imm = 1'b1; imm_src = 3'b100;
                    wb_sel = 2'd2; exec_sel = 2'd2;
                end
                7'b1100111: begin // JALR
                    if (instruction[14:12] == 3'b000) begin
                        legal = 1'b1; reg_write = 1'b1; is_jump = 1'b1;
                        is_jalr = 1'b1; operand_b_imm = 1'b1;
                        imm_src = 3'b000; wb_sel = 2'd2; exec_sel = 2'd2;
                    end
                end
                7'b1100011: begin // Conditional branches
                    case (instruction[14:12])
                        3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: begin
                            legal = 1'b1; is_branch = 1'b1;
                            branch_type = instruction[14:12];
                            imm_src = 3'b010;
                        end
                        default: ;
                    endcase
                end
                7'b0000011: begin // Loads
                    case (instruction[14:12])
                        3'b000, 3'b100: begin legal=1'b1; mem_size=2'd0; end // LB/LBU
                        3'b001, 3'b101: begin legal=1'b1; mem_size=2'd1; end // LH/LHU
                        3'b010: begin legal=1'b1; mem_size=2'd2; end // LW
                        default: ;
                    endcase
                    if (legal) begin
                        operand_b_imm=1'b1; imm_src=3'b000; mem_read=1'b1;
                        reg_write=1'b1; wb_sel=2'd1;
                        load_unsigned=(instruction[14:12] == 3'b100 || instruction[14:12] == 3'b101);
                    end
                end
                7'b0100011: begin // Stores
                    case (instruction[14:12])
                        3'b000: begin legal=1'b1; mem_size=2'd0; end // SB
                        3'b001: begin legal=1'b1; mem_size=2'd1; end // SH
                        3'b010: begin legal=1'b1; mem_size=2'd2; end // SW
                        default: ;
                    endcase
                    if (legal) begin
                        operand_b_imm=1'b1; imm_src=3'b001; mem_write=1'b1;
                    end
                end
                7'b0010011: begin // Immediate ALU operations
                    case (instruction[14:12])
                        3'b000: begin legal=1'b1; alu_op=ALU_ADD; end // ADDI
                        3'b010: begin legal=1'b1; alu_op=ALU_SLT; end // SLTI
                        3'b011: begin legal=1'b1; alu_op=ALU_SLTU; end // SLTIU
                        3'b100: begin legal=1'b1; alu_op=ALU_XOR; end // XORI
                        3'b110: begin legal=1'b1; alu_op=ALU_OR; end // ORI
                        3'b111: begin legal=1'b1; alu_op=ALU_AND; end // ANDI
                        3'b001: if (instruction[31:25] == 7'b0000000) begin
                            legal=1'b1; alu_op=ALU_SLL;
                        end
                        3'b101: begin
                            if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_SRL; end
                            else if (instruction[31:25] == 7'b0100000) begin legal=1'b1; alu_op=ALU_SRA; end
                        end
                        default: ;
                    endcase
                    if (legal) begin reg_write=1'b1; operand_b_imm=1'b1; imm_src=3'b000; end
                end
                7'b0110011: begin // Register ALU and RV32M operations
                    if (instruction[31:25] == 7'b0000001) begin
                        legal=1'b1; reg_write=1'b1; md_start=1'b1;
                        md_op=instruction[14:12]; wb_sel=2'd3; exec_sel=2'd1;
                    end else begin
                        case (instruction[14:12])
                            3'b000: begin
                                if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_ADD; end
                                else if (instruction[31:25] == 7'b0100000) begin legal=1'b1; alu_op=ALU_SUB; end
                            end
                            3'b001: if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_SLL; end
                            3'b010: if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_SLT; end
                            3'b011: if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_SLTU; end
                            3'b100: if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_XOR; end
                            3'b101: begin
                                if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_SRL; end
                                else if (instruction[31:25] == 7'b0100000) begin legal=1'b1; alu_op=ALU_SRA; end
                            end
                            3'b110: if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_OR; end
                            3'b111: if (instruction[31:25] == 7'b0000000) begin legal=1'b1; alu_op=ALU_AND; end
                            default: ;
                        endcase
                        if (legal) reg_write=1'b1;
                    end
                end
                // FENCE, SYSTEM, and unsupported/illegal encodings are NOPs.
                default: ;
            endcase
        end

        if (!legal) begin
            alu_op=ALU_ADD; operand_a_sel=2'd0; operand_b_imm=1'b0;
            imm_src=3'b000; is_branch=1'b0; branch_type=3'b000;
            is_jump=1'b0; is_jalr=1'b0; mem_read=1'b0; mem_write=1'b0;
            mem_size=2'd2; load_unsigned=1'b0; reg_write=1'b0;
            wb_sel=2'd0; exec_sel=2'd0; md_start=1'b0; md_op=3'b000;
        end
    end
endmodule
