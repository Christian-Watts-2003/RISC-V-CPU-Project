/** Archived single-cycle CPU wrapper; original implementation retained here. */
module cpu (
    input logic clk, reset,
    input logic [31:0] instruction, mem_read_data,
    output logic [31:0] pc, mem_addr, mem_write_data,
    output logic mem_read, mem_write
);
    logic [3:0] alu_op;
    logic reg_write, branch, jump, alu_src, is_muldiv, zero;
    logic [2:0] imm_src, muldiv_op;
    controller u_controller (
        .opcode(instruction[6:0]), .funct3(instruction[14:12]),
        .funct7(instruction[31:25]), .alu_op(alu_op),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .imm_src(imm_src), .branch(branch), .jump(jump), .alu_src(alu_src),
        .is_muldiv(is_muldiv), .muldiv_op(muldiv_op)
    );
    datapath u_datapath (
        .clk(clk), .reset(reset), .instruction(instruction),
        .mem_read_data(mem_read_data), .alu_op(alu_op),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .imm_src(imm_src), .branch(branch), .jump(jump), .alu_src(alu_src),
        .is_muldiv(is_muldiv), .muldiv_op(muldiv_op), .mem_addr(mem_addr),
        .mem_write_data(mem_write_data), .pc(pc), .zero(zero)
    );
endmodule
