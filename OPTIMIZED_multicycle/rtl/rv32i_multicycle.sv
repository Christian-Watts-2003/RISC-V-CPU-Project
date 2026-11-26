// Multi-cycle RV32I core with optional fetch predecode and OR selection.
module rv32i_multicycle #(
    parameter PREDECODE = 1'b1,
    parameter OR_SELECT = 1'b1
) (
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
    reg        alu_src_reg;
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
    wire [31:0] register_write_data;
    wire [31:0] selected_execute_result;
    wire [31:0] decode_instruction = PREDECODE ? instruction : instruction_reg;
    wire [22:0] decoder_control;
    reg [22:0] predecoded_control;
    wire [22:0] selected_control = PREDECODE ? predecoded_control : decoder_control;
    wire unused_is_muldiv;
    wire [2:0] unused_muldiv_op;

    assign {legal, alu_op, reg_write, ctrl_mem_read, ctrl_mem_write, imm_src,
            operand_a_sel, alu_src, branch, branch_type, jump, jalr, mem_size,
            load_unsigned} = selected_control;

    controller u_controller (
        .opcode(decode_instruction[6:0]),
        .funct3(decode_instruction[14:12]),
        .funct7(decode_instruction[31:25]),
        .legal(decoder_control[22]),
        .alu_op(decoder_control[21:18]),
        .reg_write(decoder_control[17]),
        .mem_read(decoder_control[16]),
        .mem_write(decoder_control[15]),
        .imm_src(decoder_control[14:12]),
        .operand_a_sel(decoder_control[11:10]),
        .alu_src(decoder_control[9]),
        .branch(decoder_control[8]),
        .branch_type(decoder_control[7:5]),
        .jump(decoder_control[4]),
        .jalr(decoder_control[3]),
        .mem_size(decoder_control[2:1]),
        .load_unsigned(decoder_control[0]),
        .is_muldiv(unused_is_muldiv),
        .muldiv_op(unused_muldiv_op)
    );

    generate
        if (OR_SELECT) begin : gen_or_select
            wire select_link = legal_reg && jump_reg;
            assign selected_execute_result = (link_value & {32{select_link}}) |
                                             (alu_result & {32{!select_link}});
            assign register_write_data = (load_value_reg & {32{mem_read_reg}}) |
                                         (execute_result & {32{!mem_read_reg}});
        end else begin : gen_mux_select
            assign selected_execute_result = (legal_reg && jump_reg) ? link_value : alu_result;
            assign register_write_data = mem_read_reg ? load_value_reg : execute_result;
        end
    endgenerate

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
            predecoded_control <= 23'b0;
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
                        if (PREDECODE)
                            predecoded_control <= decoder_control;
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
                        execute_result <= selected_execute_result;
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
