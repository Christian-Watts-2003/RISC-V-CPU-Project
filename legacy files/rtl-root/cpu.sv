/**
 * Single-cycle RV32 CPU integration.
 *
 * The controller decodes the current instruction and the datapath performs
 * execution, register writeback, and PC update. Instruction and data memories
 * are external to this module.
 */
module cpu (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instruction,
    input  logic [31:0] mem_read_data,

    output logic [31:0] pc,
    output logic [31:0] mem_addr,
    output logic [31:0] mem_write_data,
    output logic        mem_read,
    output logic        mem_write
);

    logic [3:0] alu_op;
    logic       reg_write;
    logic [2:0] imm_src;
    logic       branch;
    logic       jump;
    logic       alu_src;
    logic       is_muldiv;
    logic [2:0] muldiv_op;
    logic       zero;

    controller u_controller (
        .opcode    (instruction[6:0]),
        .funct3    (instruction[14:12]),
        .funct7    (instruction[31:25]),
        .alu_op    (alu_op),
        .reg_write (reg_write),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .imm_src   (imm_src),
        .branch    (branch),
        .jump      (jump),
        .alu_src   (alu_src),
        .is_muldiv (is_muldiv),
        .muldiv_op (muldiv_op)
    );

    datapath u_datapath (
        .clk           (clk),
        .reset         (reset),
        .instruction   (instruction),
        .mem_read_data (mem_read_data),
        .alu_op        (alu_op),
        .reg_write     (reg_write),
        .mem_read      (mem_read),
        .mem_write     (mem_write),
        .imm_src       (imm_src),
        .branch        (branch),
        .jump          (jump),
        .alu_src       (alu_src),
        .is_muldiv     (is_muldiv),
        .muldiv_op     (muldiv_op),
        .mem_addr      (mem_addr),
        .mem_write_data(mem_write_data),
        .pc            (pc),
        .zero          (zero)
    );

endmodule
