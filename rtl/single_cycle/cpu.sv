// Single-cycle processor interface with external combinational instruction/load data.
module cpu (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] instruction,
    input  wire [31:0] mem_read_data,
    output wire [31:0] pc,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_write_data,
    output wire [3:0]  mem_write_strobe,
    output wire        mem_read,
    output wire        mem_write
);
    wire legal;
    wire [3:0] alu_op;
    wire reg_write, branch, jump, alu_src, is_muldiv, jalr;
    wire [2:0] imm_src, branch_type, muldiv_op;
    wire [1:0] operand_a_sel, mem_size;
    wire load_unsigned;

    controller u_controller (
        .opcode(instruction[6:0]), .funct3(instruction[14:12]), .funct7(instruction[31:25]),
        .legal(legal), .alu_op(alu_op), .reg_write(reg_write), .mem_read(mem_read),
        .mem_write(mem_write), .imm_src(imm_src), .operand_a_sel(operand_a_sel),
        .alu_src(alu_src), .branch(branch), .branch_type(branch_type), .jump(jump),
        .jalr(jalr), .mem_size(mem_size), .load_unsigned(load_unsigned),
        .is_muldiv(is_muldiv), .muldiv_op(muldiv_op)
    );

    datapath u_datapath (
        .clk(clk), .reset(reset), .instruction(instruction), .mem_read_data(mem_read_data),
        .alu_op(alu_op), .legal(legal), .reg_write(reg_write), .mem_read(mem_read),
        .mem_write(mem_write), .imm_src(imm_src), .operand_a_sel(operand_a_sel),
        .alu_src(alu_src), .branch(branch), .branch_type(branch_type), .jump(jump),
        .jalr(jalr), .mem_size(mem_size), .load_unsigned(load_unsigned),
        .is_muldiv(is_muldiv), .muldiv_op(muldiv_op), .mem_addr(mem_addr),
        .mem_write_data(mem_write_data), .mem_write_strobe(mem_write_strobe),
        .mem_read_enable(mem_read), .pc(pc)
    );
    assign mem_write = legal && mem_write;
endmodule
