/** Archived single-cycle datapath. */
module datapath (
    input logic clk, reset,
    input logic [31:0] instruction, mem_read_data,
    input logic [3:0] alu_op,
    input logic reg_write, mem_read, mem_write,
    input logic [2:0] imm_src,
    input logic branch, jump, alu_src, is_muldiv,
    input logic [2:0] muldiv_op,
    output logic [31:0] mem_addr, mem_write_data, pc,
    output logic zero
);
    wire [4:0] rs1=instruction[19:15], rs2=instruction[24:20], rd=instruction[11:7];
    wire [31:0] reg_data1, reg_data2, imm, alu_result, muldiv_result;
    logic [31:0] writeback_data, pc_next;
    wire [31:0] pc_plus_4=pc+32'd4;
    wire [31:0] branch_target=pc+imm;
    wire [31:0] jalr_target=reg_data1+imm;
    wire illegal_op, muldiv_valid;
    regfile datapath_regfile (.clk(clk), .rs1(rs1), .rs2(rs2), .rd(rd),
        .write_data(writeback_data), .reg_write(reg_write),
        .read_data1(reg_data1), .read_data2(reg_data2));
    imm_gen datapath_imm_gen (.instruction(instruction), .imm_src(imm_src), .imm_value(imm));
    alu datapath_alu (.a(reg_data1), .b(alu_src?imm:reg_data2), .alu_op(alu_op),
        .result(alu_result), .zero(zero), .illegal_op(illegal_op));
    muldiv datapath_muldiv (.clk(clk), .reset(reset), .start(is_muldiv),
        .muldiv_op(muldiv_op), .a(reg_data1), .b(reg_data2),
        .result(muldiv_result), .valid(muldiv_valid));
    always @* begin
        if (jump) writeback_data=pc_plus_4;
        else if (mem_read) writeback_data=mem_read_data;
        else if (is_muldiv) writeback_data=muldiv_result;
        else writeback_data=alu_result;
        if (branch && zero) pc_next=branch_target;
        else if (jump && alu_src) pc_next=jalr_target & 32'hFFFF_FFFE;
        else if (jump) pc_next=branch_target;
        else pc_next=pc_plus_4;
    end
    always @(posedge clk) begin
        if (reset) pc<=32'b0;
        else pc<=pc_next;
    end
    assign mem_addr=alu_result;
    assign mem_write_data=reg_data2;
endmodule
