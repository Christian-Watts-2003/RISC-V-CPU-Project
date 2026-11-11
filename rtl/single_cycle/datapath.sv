// Single-cycle RV32I/RV32M datapath. Memory reads are combinational;
// stores are committed synchronously by the external memory on the clock edge.
module datapath (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction,
    input  wire [31:0] mem_read_data,
    input  wire [3:0]  alu_op,
    input  wire        legal,
    input  wire        reg_write,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  imm_src,
    input  wire [1:0]  operand_a_sel,
    input  wire        alu_src,
    input  wire        branch,
    input  wire [2:0]  branch_type,
    input  wire        jump,
    input  wire        jalr,
    input  wire [1:0]  mem_size,
    input  wire        load_unsigned,
    input  wire        is_muldiv,
    input  wire [2:0]  muldiv_op,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire [3:0]  mem_write_strobe,
    output wire        mem_read_enable,
    output reg  [31:0] pc
);
    wire [4:0] rs1=instruction[19:15], rs2=instruction[24:20], rd=instruction[11:7];
    wire [31:0] rs1_data, rs2_data, imm, alu_a, alu_b, alu_result;
    wire [31:0] muldiv_result, load_value, link_value, branch_target;
    wire [31:0] pc_next;
    wire branch_taken, alu_zero, alu_illegal;
    wire [31:0] writeback_data;

    regfile u_regfile (
        .clk(clk), .rs1(rs1), .rs2(rs2), .rd(rd),
        .write_data(writeback_data), .reg_write(legal && reg_write),
        .read_data1(rs1_data), .read_data2(rs2_data)
    );
    imm_gen u_imm_gen (.instruction(instruction), .imm_src(imm_src), .imm_value(imm));

    assign alu_a = (operand_a_sel==2'd1) ? pc :
                   (operand_a_sel==2'd2) ? 32'b0 : rs1_data;
    assign alu_b = alu_src ? imm : rs2_data;
    alu u_alu (.a(alu_a), .b(alu_b), .alu_op(alu_op),
               .result(alu_result), .zero(alu_zero), .illegal_op(alu_illegal));

    muldiv u_muldiv (.clk(clk), .reset(reset), .start(legal && is_muldiv),
                     .muldiv_op(muldiv_op), .a(rs1_data), .b(rs2_data),
                     .result(muldiv_result), .valid());

    branch_unit u_branch (.pc(pc), .imm(imm), .rs1_value(rs1_data),
        .rs2_value(rs2_data), .branch_en(legal && branch),
        .branch_type(branch_type), .jump_en(legal && jump), .jalr_en(jalr),
        .taken(branch_taken), .target(branch_target), .link_value(link_value));

    lsu u_lsu (.address(alu_result), .store_data(rs2_data), .size(mem_size),
        .load_unsigned(load_unsigned), .read_word(mem_read_data),
        .dmem_addr(mem_addr), .dmem_wdata(mem_write_data),
        .dmem_wstrb(mem_write_strobe), .load_data(load_value));

    assign mem_read_enable = legal && mem_read;
    assign mem_write_strobe = (legal && mem_write) ? mem_write_strobe_raw : 4'b0000;
    wire [3:0] mem_write_strobe_raw;
    // The LSU computes lane placement; the legality/control gate prevents
    // non-store instructions from asserting byte strobes.

    assign writeback_data = (jump && legal) ? link_value :
                            (mem_read && legal) ? load_value :
                            (is_muldiv && legal) ? muldiv_result : alu_result;

    assign pc_next = (legal && branch && branch_taken) ? branch_target :
                     (legal && jump) ? branch_target : pc + 32'd4;
    always @(posedge clk) begin
        if (reset) pc <= 32'b0;
        else pc <= pc_next;
    end
endmodule
