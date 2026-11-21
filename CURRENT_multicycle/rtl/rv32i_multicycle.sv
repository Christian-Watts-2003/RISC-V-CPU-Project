// Compact multi-cycle RV32I core.
//
// The existing single-cycle modules remain the reference implementation.
// This core reuses their controller, immediate generator, ALU, LSU, and
// register file while separating fetch, decode, execute, memory, and
// writeback into distinct clocked phases.
module rv32i_multicycle (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire [31:0] instruction,
    input  wire [31:0] mem_read_data,
    input  wire        mem_ready,
    output wire [31:0] pc,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire [3:0]  mem_write_strobe,
    output wire        mem_valid,
    output wire        mem_read,
    output wire        mem_write,
    output wire        retire_valid,
    output wire [31:0] retire_pc,
    output wire [31:0] retire_instruction
);
    localparam [2:0] ST_FETCH  = 3'd0;
    localparam [2:0] ST_DECODE = 3'd1;
    localparam [2:0] ST_EXEC   = 3'd2;
    localparam [2:0] ST_MEM    = 3'd3;
    localparam [2:0] ST_WB     = 3'd4;

    reg [2:0] state;
    reg [31:0] pc_reg;
    reg [31:0] instruction_reg;
    reg [31:0] instruction_pc;
    reg [31:0] operand_a_reg;
    reg [31:0] operand_b_reg;
    reg [31:0] immediate_reg;
    reg [4:0]  rd_reg;
    reg [2:0]  funct3_reg;
    reg        legal_reg;
    reg        reg_write_reg;
    reg        mem_read_reg;
    reg        mem_write_reg;
    reg        branch_reg;
    reg [2:0]  branch_type_reg;
    reg        jump_reg;
    reg        jalr_reg;
    reg [1:0]  mem_size_reg;
    reg        load_unsigned_reg;
    reg [3:0]  alu_op_reg;
    reg [31:0] execute_result;
    reg [31:0] load_value_reg;
    reg        branch_taken_reg;
    reg [31:0] branch_target_reg;
    reg        retire_valid_reg;

    wire legal;
    wire [3:0] alu_op;
    wire reg_write;
    wire ctrl_mem_read;
    wire ctrl_mem_write;
    wire [2:0] imm_src;
    wire [1:0] operand_a_sel;
    wire alu_src;
    wire branch;
    wire [2:0] branch_type;
    wire jump;
    wire jalr;
    wire [1:0] mem_size;
    wire load_unsigned;
    wire is_muldiv;
    wire [2:0] muldiv_op;
    wire [31:0] immediate;
    wire [31:0] decoded_rs1;
    wire [31:0] decoded_rs2;
    wire [31:0] reg_read_data1;
    wire [31:0] reg_read_data2;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire [31:0] lsu_load_value;
    wire [31:0] lsu_mem_addr;
    wire [31:0] lsu_mem_write_data;
    wire [3:0] lsu_mem_write_strobe;
    wire branch_taken;
    wire [31:0] branch_target;
    wire [31:0] link_value;
    wire [31:0] register_write_data = mem_read_reg ? load_value_reg :
                                      execute_result;

    controller u_controller (
        .opcode(instruction_reg[6:0]),
        .funct3(instruction_reg[14:12]),
        .funct7(instruction_reg[31:25]),
        .legal(legal),
        .alu_op(alu_op),
        .reg_write(reg_write),
        .mem_read(ctrl_mem_read),
        .mem_write(ctrl_mem_write),
        .imm_src(imm_src),
        .operand_a_sel(operand_a_sel),
        .alu_src(alu_src),
        .branch(branch),
        .branch_type(branch_type),
        .jump(jump),
        .jalr(jalr),
        .mem_size(mem_size),
        .load_unsigned(load_unsigned),
        .is_muldiv(is_muldiv),
        .muldiv_op(muldiv_op)
    );

    imm_gen u_imm_gen (
        .instruction(instruction_reg),
        .imm_src(imm_src),
        .imm_value(immediate)
    );

    regfile u_regfile (
        .clk(clk),
        .rs1(instruction_reg[19:15]),
        .rs2(instruction_reg[24:20]),
        .rd(rd_reg),
        .write_data(register_write_data),
        .reg_write(enable && state == ST_WB && legal_reg && reg_write_reg),
        .read_data1(reg_read_data1),
        .read_data2(reg_read_data2)
    );

    assign decoded_rs1 = reg_read_data1;
    assign decoded_rs2 = reg_read_data2;

    assign alu_b = alu_src_reg ? immediate_reg : operand_b_reg;

    reg alu_src_reg;
    alu u_alu (
        .a(operand_a_reg),
        .b(alu_b),
        .alu_op(alu_op_reg),
        .result(alu_result),
        .zero(),
        .illegal_op()
    );

    branch_unit u_branch (
        .pc(instruction_pc),
        .imm(immediate_reg),
        .rs1_value(operand_a_reg),
        .rs2_value(operand_b_reg),
        .branch_en(branch_reg),
        .branch_type(branch_type_reg),
        .jump_en(jump_reg),
        .jalr_en(jalr_reg),
        .taken(branch_taken),
        .target(branch_target),
        .link_value(link_value)
    );

    lsu u_lsu (
        .address(execute_result),
        .store_data(operand_b_reg),
        .size(mem_size_reg),
        .load_unsigned(load_unsigned_reg),
        .read_word(mem_read_data),
        .dmem_addr(lsu_mem_addr),
        .dmem_wdata(lsu_mem_write_data),
        .dmem_wstrb(lsu_mem_write_strobe),
        .load_data(lsu_load_value)
    );

    assign pc = pc_reg;
    assign mem_addr = lsu_mem_addr;
    assign mem_write_data = lsu_mem_write_data;
    assign mem_write_strobe = (state == ST_MEM && mem_write_reg) ?
                              lsu_mem_write_strobe : 4'b0;
    assign mem_valid = state == ST_MEM && (mem_read_reg || mem_write_reg);
    assign mem_read = state == ST_MEM && mem_read_reg;
    assign mem_write = state == ST_MEM && mem_write_reg;
    assign retire_valid = retire_valid_reg;
    assign retire_pc = instruction_pc;
    assign retire_instruction = instruction_reg;

    always @(posedge clk) begin
        if (reset) begin
            state <= ST_FETCH;
            pc_reg <= 32'b0;
            instruction_reg <= 32'b0;
            instruction_pc <= 32'b0;
            operand_a_reg <= 32'b0;
            operand_b_reg <= 32'b0;
            immediate_reg <= 32'b0;
            rd_reg <= 5'b0;
            funct3_reg <= 3'b0;
            legal_reg <= 1'b0;
            reg_write_reg <= 1'b0;
            mem_read_reg <= 1'b0;
            mem_write_reg <= 1'b0;
            branch_reg <= 1'b0;
            branch_type_reg <= 3'b0;
            jump_reg <= 1'b0;
            jalr_reg <= 1'b0;
            mem_size_reg <= 2'b0;
            load_unsigned_reg <= 1'b0;
            alu_op_reg <= 4'b0;
            alu_src_reg <= 1'b0;
            execute_result <= 32'b0;
            load_value_reg <= 32'b0;
            branch_taken_reg <= 1'b0;
            branch_target_reg <= 32'b0;
            retire_valid_reg <= 1'b0;
        end else begin
            retire_valid_reg <= 1'b0;
            if (!enable) begin
                state <= state;
            end else begin
                case (state)
                    ST_FETCH: begin
                        instruction_reg <= instruction;
                        instruction_pc <= pc_reg;
                        state <= ST_DECODE;
                    end
                    ST_DECODE: begin
                        operand_a_reg <= (operand_a_sel == 2'd1) ? instruction_pc :
                                         (operand_a_sel == 2'd2) ? 32'b0 : decoded_rs1;
                        operand_b_reg <= decoded_rs2;
                        immediate_reg <= immediate;
                        rd_reg <= instruction_reg[11:7];
                        funct3_reg <= instruction_reg[14:12];
                        legal_reg <= legal;
                        reg_write_reg <= reg_write;
                        mem_read_reg <= ctrl_mem_read;
                        mem_write_reg <= ctrl_mem_write;
                        branch_reg <= branch;
                        branch_type_reg <= branch_type;
                        jump_reg <= jump;
                        jalr_reg <= jalr;
                        mem_size_reg <= mem_size;
                        load_unsigned_reg <= load_unsigned;
                        alu_op_reg <= alu_op;
                        alu_src_reg <= alu_src;
                        state <= ST_EXEC;
                    end
                    ST_EXEC: begin
                        execute_result <= (legal_reg && jump_reg) ? link_value : alu_result;
                        branch_taken_reg <= branch_taken;
                        branch_target_reg <= branch_target;
                        if (legal_reg && (mem_read_reg || mem_write_reg))
                            state <= ST_MEM;
                        else if (legal_reg && (branch_reg || jump_reg))
                            state <= ST_WB;
                        else
                            state <= ST_WB;
                    end
                    ST_MEM: begin
                        if (mem_ready) begin
                            if (mem_read_reg)
                                load_value_reg <= lsu_load_value;
                            state <= ST_WB;
                        end
                    end
                    ST_WB: begin
                        if (legal_reg && reg_write_reg) begin
                        end
                        if (legal_reg && branch_reg && branch_taken_reg)
                            pc_reg <= branch_target_reg;
                        else if (legal_reg && jump_reg)
                            pc_reg <= branch_target_reg;
                        else
                            pc_reg <= pc_reg + 32'd4;
                        retire_valid_reg <= 1'b1;
                        state <= ST_FETCH;
                    end
                    default: state <= ST_FETCH;
                endcase
            end
        end
    end
endmodule
