module rv32im_core #(
    parameter integer PREDECODE = 0,
    parameter integer OR_SELECT = 0
) (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire [3:0]  dmem_wstrb,
    output wire        dmem_re,
    input  wire [31:0] dmem_rdata
);

    wire [31:0] pc;
    wire        if_id_valid;
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;

    wire fetch_hold = 1'b0;
    wire ifid_hold = 1'b0;
    wire ifid_flush = 1'b0;
    wire fetch_redirect = 1'b0;
    wire [31:0] fetch_redirect_pc = 32'b0;

    fetch_unit u_fetch (
        .clk(clk), .rst(rst), .imem_rdata(imem_rdata),
        .hold_pc(fetch_hold), .hold_ifid(ifid_hold),
        .flush_ifid(ifid_flush), .redirect(fetch_redirect),
        .redirect_pc(fetch_redirect_pc), .pc(pc),
        .ifid_valid(if_id_valid), .ifid_pc(if_id_pc), .ifid_instr(if_id_instr)
    );

    wire decode_legal;
    wire [4:0] dec_rs1, dec_rs2, dec_rd;
    wire [3:0] dec_alu_op;
    wire [1:0] dec_operand_a_sel;
    wire dec_operand_b_imm;
    wire [2:0] dec_imm_src;
    wire dec_is_branch;
    wire [2:0] dec_branch_type;
    wire dec_is_jump, dec_is_jalr;
    wire dec_mem_read, dec_mem_write;
    wire [1:0] dec_mem_size;
    wire dec_load_unsigned, dec_reg_write;
    wire [1:0] dec_wb_sel, dec_exec_sel;
    wire dec_md_start;
    wire [2:0] dec_md_op;

    decode_unit u_decode (
        .instr_valid(if_id_valid), .instruction(if_id_instr), .legal(decode_legal),
        .rs1(dec_rs1), .rs2(dec_rs2), .rd(dec_rd), .alu_op(dec_alu_op),
        .operand_a_sel(dec_operand_a_sel), .operand_b_imm(dec_operand_b_imm),
        .imm_src(dec_imm_src), .is_branch(dec_is_branch),
        .branch_type(dec_branch_type), .is_jump(dec_is_jump), .is_jalr(dec_is_jalr),
        .mem_read(dec_mem_read), .mem_write(dec_mem_write), .mem_size(dec_mem_size),
        .load_unsigned(dec_load_unsigned), .reg_write(dec_reg_write),
        .wb_sel(dec_wb_sel), .exec_sel(dec_exec_sel), .md_start(dec_md_start), .md_op(dec_md_op)
    );

    wire [31:0] imm_value;
    imm_gen u_imm_gen (.instruction(if_id_instr), .imm_src(dec_imm_src), .imm_value(imm_value));

    wire [31:0] regfile_r1, regfile_r2;
    regfile u_regfile (
        .clk(clk), .rs1(dec_rs1), .rs2(dec_rs2), .rd(5'b0),
        .write_data(32'b0), .reg_write(1'b0),
        .read_data1(regfile_r1), .read_data2(regfile_r2)
    );

    assign imem_addr = pc;
    assign dmem_addr = 32'b0;
    assign dmem_wdata = 32'b0;
    assign dmem_wstrb = 4'b0000;
    assign dmem_re = 1'b0;

    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_instr;
    reg id_ex_valid;
    reg [31:0] ex_mem_pc;
    reg [31:0] ex_mem_instr;
    reg ex_mem_valid;
    reg [31:0] mem_wb_pc;
    reg [31:0] mem_wb_instr;
    reg mem_wb_valid;

    always @(posedge clk) begin
        if (rst) begin
            id_ex_valid <= 1'b0;
            ex_mem_valid <= 1'b0;
            mem_wb_valid <= 1'b0;
        end else begin
            id_ex_pc <= if_id_pc;
            id_ex_instr <= if_id_instr;
            id_ex_valid <= if_id_valid;
            ex_mem_pc <= id_ex_pc;
            ex_mem_instr <= id_ex_instr;
            ex_mem_valid <= id_ex_valid;
            mem_wb_pc <= ex_mem_pc;
            mem_wb_instr <= ex_mem_instr;
            mem_wb_valid <= ex_mem_valid;
        end
    end
endmodule
