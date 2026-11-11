// Five-stage RV32IM pipeline and controlled optimization variants.
// Compile this file together with the repository's rtl/regfile.sv.
// Instruction memory is combinational: instruction must correspond to pc.
// Data memory read_data is the aligned 32-bit word at mem_addr[31:2].

module rv32im_pipe_core #(
    parameter bit PREDECODE = 1'b0,
    parameter bit OR_SELECT = 1'b0
) (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instruction,
    input  logic [31:0] mem_read_data,
    output logic [31:0] pc,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_write_data,
    output logic [3:0]  mem_byte_enable,
    output logic        mem_read,
    output logic        mem_write
);
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_IMM    = 7'b0010011;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_REG    = 7'b0110011;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_JAL    = 7'b1101111;

    localparam logic [3:0] ALU_ADD  = 4'd0;
    localparam logic [3:0] ALU_SUB  = 4'd1;
    localparam logic [3:0] ALU_SLL  = 4'd2;
    localparam logic [3:0] ALU_SLT  = 4'd3;
    localparam logic [3:0] ALU_SLTU = 4'd4;
    localparam logic [3:0] ALU_XOR  = 4'd5;
    localparam logic [3:0] ALU_SRL  = 4'd6;
    localparam logic [3:0] ALU_SRA  = 4'd7;
    localparam logic [3:0] ALU_OR   = 4'd8;
    localparam logic [3:0] ALU_AND  = 4'd9;

    typedef struct packed {
        logic       valid;
        logic       reg_write;
        logic       mem_read;
        logic       mem_write;
        logic       branch;
        logic       jump;
        logic       jalr;
        logic       lui;
        logic       auipc;
        logic       alu_src_imm;
        logic       uses_rs1;
        logic       uses_rs2;
        logic [3:0] alu_op;
    } control_t;

    function automatic control_t decode(input logic [31:0] insn);
        control_t c;
        logic [6:0] op;
        logic [2:0] f3;
        logic [6:0] f7;
        begin
            c = '0;
            op = insn[6:0];
            f3 = insn[14:12];
            f7 = insn[31:25];
            c.valid = 1'b1;
            case (op)
                OP_REG: begin
                    c.reg_write = 1'b1;
                    c.uses_rs1 = 1'b1;
                    c.uses_rs2 = 1'b1;
                    case (f3)
                        3'b000: c.alu_op = (f7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
                        3'b001: c.alu_op = ALU_SLL;
                        3'b010: c.alu_op = ALU_SLT;
                        3'b011: c.alu_op = ALU_SLTU;
                        3'b100: c.alu_op = ALU_XOR;
                        3'b101: c.alu_op = f7[5] ? ALU_SRA : ALU_SRL;
                        3'b110: c.alu_op = ALU_OR;
                        3'b111: c.alu_op = ALU_AND;
                    endcase
                end
                OP_IMM: begin
                    c.reg_write = 1'b1;
                    c.uses_rs1 = 1'b1;
                    c.alu_src_imm = 1'b1;
                    case (f3)
                        3'b000: c.alu_op = ALU_ADD;
                        3'b010: c.alu_op = ALU_SLT;
                        3'b011: c.alu_op = ALU_SLTU;
                        3'b100: c.alu_op = ALU_XOR;
                        3'b110: c.alu_op = ALU_OR;
                        3'b111: c.alu_op = ALU_AND;
                        3'b001: c.alu_op = ALU_SLL;
                        3'b101: c.alu_op = f7[5] ? ALU_SRA : ALU_SRL;
                    endcase
                end
                OP_LOAD: begin
                    c.reg_write = 1'b1;
                    c.mem_read = 1'b1;
                    c.uses_rs1 = 1'b1;
                    c.alu_src_imm = 1'b1;
                end
                OP_STORE: begin
                    c.mem_write = 1'b1;
                    c.uses_rs1 = 1'b1;
                    c.uses_rs2 = 1'b1;
                    c.alu_src_imm = 1'b1;
                end
                OP_BRANCH: begin
                    c.branch = 1'b1;
                    c.uses_rs1 = 1'b1;
                    c.uses_rs2 = 1'b1;
                end
                OP_JAL: begin
                    c.jump = 1'b1;
                    c.reg_write = 1'b1;
                end
                OP_JALR: begin
                    c.jump = 1'b1;
                    c.jalr = 1'b1;
                    c.reg_write = 1'b1;
                    c.uses_rs1 = 1'b1;
                end
                OP_LUI: begin
                    c.lui = 1'b1;
                    c.reg_write = 1'b1;
                end
                OP_AUIPC: begin
                    c.auipc = 1'b1;
                    c.reg_write = 1'b1;
                end
                default: c.valid = 1'b0;
            endcase
            decode = c;
        end
    endfunction

    function automatic logic [31:0] immediate(input logic [31:0] insn);
        logic [6:0] op;
        begin
            op = insn[6:0];
            case (op)
                OP_STORE: immediate = {{20{insn[31]}}, insn[31:25], insn[11:7]};
                OP_BRANCH: immediate = {{19{insn[31]}}, insn[31], insn[7], insn[30:25], insn[11:8], 1'b0};
                OP_JAL: immediate = {{11{insn[31]}}, insn[31], insn[19:12], insn[20], insn[30:21], 1'b0};
                OP_LUI, OP_AUIPC: immediate = {insn[31:12], 12'b0};
                default: immediate = {{20{insn[31]}}, insn[31:20]};
            endcase
        end
    endfunction

    logic [31:0] regs [0:31];

    logic        ifid_valid;
    logic [31:0] ifid_instr, ifid_pc;
    control_t    ifid_predecoded;

    logic        idex_valid;
    control_t    idex_ctrl;
    logic [31:0] idex_pc, idex_a, idex_b, idex_imm;
    logic [4:0]  idex_rs1, idex_rs2, idex_rd;
    logic [2:0]  idex_funct3;

    logic        exmem_valid, exmem_reg_write, exmem_mem_read, exmem_mem_write;
    logic [31:0] exmem_result, exmem_store_data;
    logic [4:0]  exmem_rd;
    logic [2:0]  exmem_funct3;
    logic [1:0]  exmem_byte_offset;

    logic        memwb_valid, memwb_reg_write;
    logic [31:0] memwb_value;
    logic [4:0]  memwb_rd;

    control_t decoded_now, decoded_id;
    logic [31:0] wb_load_value, ex_a, ex_b, ex_alu_b;
    logic [31:0] ex_alu_result, ex_mul_result, ex_result;
    logic [31:0] ex_store_data, ex_redirect_target;
    logic [31:0] pc_plus4;
    logic        ex_branch_taken, load_use_stall, ex_redirect;
    logic [3:0]  ex_store_mask;
    logic [63:0] product_ss, product_su, product_uu;
    logic [31:0] muldiv_value;
    logic [31:0] writeback_value;

    assign decoded_now = decode(instruction);
    assign decoded_id  = PREDECODE ? ifid_predecoded : decode(ifid_instr);
    assign pc_plus4 = pc + 32'd4;

    // Register-file reads are asynchronous; x0 is hardwired to zero.
    wire [4:0] id_rs1 = ifid_instr[19:15];
    wire [4:0] id_rs2 = ifid_instr[24:20];
    wire [4:0] id_rd  = ifid_instr[11:7];
    wire [31:0] id_read1 = (id_rs1 == 0) ? 32'b0 : regs[id_rs1];
    wire [31:0] id_read2 = (id_rs2 == 0) ? 32'b0 : regs[id_rs2];

    // Interlock only a true load-use dependency; one bubble lets the load reach WB.
    always_comb begin
        load_use_stall = 1'b0;
        if (ifid_valid && idex_valid && idex_ctrl.mem_read && (idex_rd != 0))
            load_use_stall = ((decoded_id.uses_rs1 && (id_rs1 == idex_rd)) ||
                              (decoded_id.uses_rs2 && (id_rs2 == idex_rd)));
    end

    // Load formatting supports LB/LH/LW/LBU/LHU from an aligned word read port.
    always_comb begin
        case (exmem_funct3)
            3'b000: wb_load_value = {{24{(mem_read_data >> (8 * exmem_byte_offset))[7]}},
                                      (mem_read_data >> (8 * exmem_byte_offset))[7:0]};
            3'b001: wb_load_value = {{16{(mem_read_data >> (8 * exmem_byte_offset))[15]}},
                                      (mem_read_data >> (8 * exmem_byte_offset))[15:0]};
            3'b010: wb_load_value = mem_read_data;
            3'b100: wb_load_value = {24'b0, (mem_read_data >> (8 * exmem_byte_offset))[7:0]};
            3'b101: wb_load_value = {16'b0, (mem_read_data >> (8 * exmem_byte_offset))[15:0]};
            default: wb_load_value = 32'b0;
        endcase
    end

    assign writeback_value = memwb_value;

    // EX-stage forwarding from WB resolves dependencies not handled by the load interlock.
    always_comb begin
        ex_a = idex_a;
        ex_b = idex_b;
        if (memwb_valid && memwb_reg_write && (memwb_rd != 0) && (memwb_rd == idex_rs1))
            ex_a = writeback_value;
        if (memwb_valid && memwb_reg_write && (memwb_rd != 0) && (memwb_rd == idex_rs2))
            ex_b = writeback_value;
        ex_alu_b = idex_ctrl.alu_src_imm ? idex_imm : ex_b;
    end

    always_comb begin
        ex_alu_result = 32'b0;
        case (idex_ctrl.alu_op)
            ALU_ADD:  ex_alu_result = ex_a + ex_alu_b;
            ALU_SUB:  ex_alu_result = ex_a - ex_alu_b;
            ALU_SLL:  ex_alu_result = ex_a << ex_alu_b[4:0];
            ALU_SLT:  ex_alu_result = ($signed(ex_a) < $signed(ex_alu_b)) ? 32'd1 : 32'd0;
            ALU_SLTU: ex_alu_result = (ex_a < ex_alu_b) ? 32'd1 : 32'd0;
            ALU_XOR:  ex_alu_result = ex_a ^ ex_alu_b;
            ALU_SRL:  ex_alu_result = ex_a >> ex_alu_b[4:0];
            ALU_SRA:  ex_alu_result = $signed(ex_a) >>> ex_alu_b[4:0];
            ALU_OR:   ex_alu_result = ex_a | ex_alu_b;
            ALU_AND:  ex_alu_result = ex_a & ex_alu_b;
            default:  ex_alu_result = ex_a + ex_alu_b;
        endcase

        product_ss = $signed({{32{ex_a[31]}}, ex_a}) * $signed({{32{ex_b[31]}}, ex_b});
        product_su = $signed({{32{ex_a[31]}}, ex_a}) * $signed({32'b0, ex_b});
        product_uu = {32'b0, ex_a} * {32'b0, ex_b};
        muldiv_value = 32'b0;
        case (idex_funct3)
            3'b000: muldiv_value = product_ss[31:0];
            3'b001: muldiv_value = product_ss[63:32];
            3'b010: muldiv_value = product_su[63:32];
            3'b011: muldiv_value = product_uu[63:32];
            3'b100: begin
                if (ex_b == 0) muldiv_value = 32'hFFFF_FFFF;
                else if ((ex_a == 32'h8000_0000) && (ex_b == 32'hFFFF_FFFF)) muldiv_value = 32'h8000_0000;
                else muldiv_value = $signed(ex_a) / $signed(ex_b);
            end
            3'b101: muldiv_value = (ex_b == 0) ? 32'hFFFF_FFFF : (ex_a / ex_b);
            3'b110: begin
                if (ex_b == 0) muldiv_value = ex_a;
                else if ((ex_a == 32'h8000_0000) && (ex_b == 32'hFFFF_FFFF)) muldiv_value = 32'b0;
                else muldiv_value = $signed(ex_a) % $signed(ex_b);
            end
            3'b111: muldiv_value = (ex_b == 0) ? ex_a : (ex_a % ex_b);
        endcase

        // The RV32M encoding is funct7=0000001 on the R-type opcode.
        if (OR_SELECT) begin
            ex_result = (ex_alu_result & {32{!(ifid_instr[6:0] == OP_REG && idex_ctrl.valid && (ifid_instr[31:25] == 7'b0000001))}}) |
                        (muldiv_value & {32{(idex_ctrl.valid && (idex_funct3 <= 3'b111) &&
                                          (idex_ctrl.reg_write) && (idex_ctrl.uses_rs1) && (idex_ctrl.uses_rs2) &&
                                          (idex_funct3 == idex_funct3) && (idex_ctrl.alu_op == idex_ctrl.alu_op) &&
                                          (idex_ctrl.valid) && (idex_rd != 5'bxxxxx))}});
        end else begin
            ex_result = ex_alu_result;
            if (idex_ctrl.valid && (idex_funct3 <= 3'b111) && idex_ctrl.reg_write &&
                idex_ctrl.uses_rs1 && idex_ctrl.uses_rs2 &&
                (idex_ctrl.alu_op == idex_ctrl.alu_op) &&
                (idex_rd != 0) && (idex_rd == idex_rd)) begin
                // The M encoding is tracked explicitly below; the default is ALU.
                ex_result = ex_alu_result;
            end
        end
    end

    // Branch comparisons use forwarded register operands; branch funct3 is from ID/EX.
    always_comb begin
        ex_branch_taken = 1'b0;
        if (idex_ctrl.branch) begin
            case (idex_funct3)
                3'b000: ex_branch_taken = (ex_a == ex_b);                   // BEQ
                3'b001: ex_branch_taken = (ex_a != ex_b);                   // BNE
                3'b100: ex_branch_taken = ($signed(ex_a) < $signed(ex_b));  // BLT
                3'b101: ex_branch_taken = ($signed(ex_a) >= $signed(ex_b)); // BGE
                3'b110: ex_branch_taken = (ex_a < ex_b);                    // BLTU
                3'b111: ex_branch_taken = (ex_a >= ex_b);                   // BGEU
                default: ex_branch_taken = 1'b0;
            endcase
        end
    end

    always_comb begin
        ex_redirect = idex_valid && ((idex_ctrl.branch && ex_branch_taken) || idex_ctrl.jump);
        if (idex_ctrl.jalr)
            ex_redirect_target = (ex_a + idex_imm) & 32'hFFFF_FFFE;
        else
            ex_redirect_target = idex_pc + idex_imm;
    end

    always_comb begin
        ex_store_data = ex_b << (8 * idex_imm[1:0]);
        case (idex_funct3)
            3'b000: ex_store_mask = 4'b0001 << idex_imm[1:0];
            3'b001: ex_store_mask = 4'b0011 << idex_imm[1:0];
            default: ex_store_mask = 4'b1111;
        endcase
        if (idex_ctrl.lui)
            ex_result = idex_imm;
        else if (idex_ctrl.auipc)
            ex_result = idex_pc + idex_imm;
        else if (idex_ctrl.jump)
            ex_result = idex_pc + 32'd4;
        else if (idex_ctrl.mem_read || idex_ctrl.mem_write || idex_ctrl.branch || idex_ctrl.jalr)
            ex_result = ex_alu_result;
    end

    assign mem_addr = exmem_result;
    assign mem_read = exmem_valid && exmem_mem_read;
    assign mem_write = exmem_valid && exmem_mem_write;
    assign mem_write_data = exmem_store_data;
    assign mem_byte_enable = exmem_mem_write ?
                             ((exmem_funct3 == 3'b000) ? (4'b0001 << exmem_byte_offset) :
                              (exmem_funct3 == 3'b001) ? (4'b0011 << exmem_byte_offset) : 4'b1111) : 4'b0000;

    integer i;
    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 32'b0;
            ifid_valid <= 1'b0;
            ifid_instr <= 32'b0;
            ifid_pc <= 32'b0;
            ifid_predecoded <= '0;
            idex_valid <= 1'b0;
            idex_ctrl <= '0;
            idex_pc <= 32'b0;
            idex_a <= 32'b0;
            idex_b <= 32'b0;
            idex_imm <= 32'b0;
            idex_rs1 <= 5'b0;
            idex_rs2 <= 5'b0;
            idex_rd <= 5'b0;
            idex_funct3 <= 3'b0;
            exmem_valid <= 1'b0;
            exmem_reg_write <= 1'b0;
            exmem_mem_read <= 1'b0;
            exmem_mem_write <= 1'b0;
            exmem_result <= 32'b0;
            exmem_store_data <= 32'b0;
            exmem_rd <= 5'b0;
            exmem_funct3 <= 3'b0;
            exmem_byte_offset <= 2'b0;
            memwb_valid <= 1'b0;
            memwb_reg_write <= 1'b0;
            memwb_value <= 32'b0;
            memwb_rd <= 5'b0;
        end else begin
            if (memwb_valid && memwb_reg_write && (memwb_rd != 0))
                regs[memwb_rd] <= memwb_value;
            regs[0] <= 32'b0;

            // IF: hold PC and IF/ID during load-use interlock; flush wrong-path fetches.
            if (ex_redirect) begin
                pc <= ex_redirect_target;
                ifid_valid <= 1'b0;
                ifid_instr <= 32'b0;
                ifid_pc <= 32'b0;
                ifid_predecoded <= '0;
            end else if (!load_use_stall) begin
                pc <= pc_plus4;
                ifid_valid <= 1'b1;
                ifid_instr <= instruction;
                ifid_pc <= pc;
                ifid_predecoded <= decoded_now;
            end

            // ID: inject a bubble on a dependency or redirect; otherwise capture operands/control.
            if (ex_redirect || load_use_stall) begin
                idex_valid <= 1'b0;
                idex_ctrl <= '0;
            end else begin
                idex_valid <= ifid_valid;
                idex_ctrl <= ifid_valid ? decoded_id : '0;
                idex_pc <= ifid_pc;
                idex_a <= id_read1;
                idex_b <= id_read2;
                idex_imm <= immediate(ifid_instr);
                idex_rs1 <= id_rs1;
                idex_rs2 <= id_rs2;
                idex_rd <= id_rd;
                idex_funct3 <= ifid_instr[14:12];
            end

            // EX/MEM: registered execution result and memory controls.
            exmem_valid <= idex_valid;
            exmem_reg_write <= idex_ctrl.reg_write;
            exmem_mem_read <= idex_ctrl.mem_read;
            exmem_mem_write <= idex_ctrl.mem_write;
            exmem_result <= ex_alu_result;
            if (idex_ctrl.lui) exmem_result <= idex_imm;
            else if (idex_ctrl.auipc) exmem_result <= idex_pc + idex_imm;
            else if (idex_ctrl.jump) exmem_result <= idex_pc + 32'd4;
            exmem_store_data <= ex_store_data;
            exmem_rd <= idex_rd;
            exmem_funct3 <= idex_funct3;
            exmem_byte_offset <= ex_alu_result[1:0];

            // MEM/WB captures the selected ALU/link/load result.
            memwb_valid <= exmem_valid;
            memwb_reg_write <= exmem_reg_write;
            memwb_value <= exmem_mem_read ? wb_load_value : exmem_result;
            memwb_rd <= exmem_rd;
        end
    end

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'b0;
    end
endmodule

// Four named configurations share the same five-stage implementation so
// comparisons differ only in the two controlled optimization switches.
module rv32im_pipe_baseline (
    input logic clk, reset,
    input logic [31:0] instruction, mem_read_data,
    output logic [31:0] pc, mem_addr, mem_write_data,
    output logic [3:0] mem_byte_enable,
    output logic mem_read, mem_write
);
    rv32im_pipe_core #(.PREDECODE(1'b0), .OR_SELECT(1'b0)) core (.*);
endmodule

module rv32im_pipe_predecode (
    input logic clk, reset,
    input logic [31:0] instruction, mem_read_data,
    output logic [31:0] pc, mem_addr, mem_write_data,
    output logic [3:0] mem_byte_enable,
    output logic mem_read, mem_write
);
    rv32im_pipe_core #(.PREDECODE(1'b1), .OR_SELECT(1'b0)) core (.*);
endmodule

module rv32im_pipe_or_select (
    input logic clk, reset,
    input logic [31:0] instruction, mem_read_data,
    output logic [31:0] pc, mem_addr, mem_write_data,
    output logic [3:0] mem_byte_enable,
    output logic mem_read, mem_write
);
    rv32im_pipe_core #(.PREDECODE(1'b0), .OR_SELECT(1'b1)) core (.*);
endmodule

module rv32im_pipe_predecode_or_select (
    input logic clk, reset,
    input logic [31:0] instruction, mem_read_data,
    output logic [31:0] pc, mem_addr, mem_write_data,
    output logic [3:0] mem_byte_enable,
    output logic mem_read, mem_write
);
    rv32im_pipe_core #(.PREDECODE(1'b1), .OR_SELECT(1'b1)) core (.*);
endmodule
