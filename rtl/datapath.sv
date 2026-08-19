/**
 * Datapath Unit
 * Connects all of the other RTL modules and adds control flow logic.
 */

module datapath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instruction,
    input  logic [31:0] mem_read_data,

    input  logic [3:0]  alu_op,
    input  logic        reg_write,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [2:0]  imm_src,
    input  logic        branch,
    input  logic        jump,
    input  logic        alu_src,
    input  logic        is_muldiv,
    input  logic [2:0]  muldiv_op,

    output logic [31:0] mem_addr,
    output logic [31:0] mem_write_data,
    output logic [31:0] pc,
    output logic        zero
);

    wire [4:0] rs1    = instruction[19:15];
    wire [4:0] rs2    = instruction[24:20];
    wire [4:0] rd     = instruction[11:7];
    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];

    wire [31:0] reg_data1;
    wire [31:0] reg_data2;
    wire [31:0] writeback_data;

    regfile datapath_regfile (
        .clk        (clk),
        .rs1        (rs1),
        .rs2        (rs2),
        .rd         (rd),
        .write_data (writeback_data),
        .reg_write  (reg_write),
        .read_data1 (reg_data1),
        .read_data2 (reg_data2)
    );

    wire [31:0] imm;

    imm_gen datapath_imm_gen (
        .instruction (instruction),
        .imm_src     (imm_src),
        .imm_value   (imm)
    );

    wire [31:0] alu_result;
    wire        illegal_op;

    alu datapath_alu (
        .a          (reg_data1),
        .b          (alu_src ? imm : reg_data2),
        .alu_op     (alu_op),
        .result     (alu_result),
        .zero       (zero),
        .illegal_op (illegal_op)
    );

    // MulDiv Integration
    wire [31:0] muldiv_result;
    wire        muldiv_valid;

    muldiv datapath_muldiv (
        .clk        (clk),
        .reset      (reset),
        .start      (is_muldiv),
        .muldiv_op  (muldiv_op),
        .a          (reg_data1),
        .b          (reg_data2),
        .result     (muldiv_result),
        .valid      (muldiv_valid)
    );

    // Writeback Mux 
    wire [31:0] pc_plus_4 = pc + 4;

    always_comb begin
        if (jump) begin
            writeback_data = pc_plus_4;
        end else if (mem_read) begin
            writeback_data = mem_read_data;
        end else if (is_muldiv) begin
            writeback_data = muldiv_result;     // RV32M result
        end else begin
            writeback_data = alu_result;
        end
    end

    // PC Logic
    wire [31:0] branch_target = pc + imm;
    wire [31:0] jal_target    = pc + imm;
    wire [31:0] jalr_target   = reg_data1 + imm;

    wire [31:0] pc_next;

    always_comb begin
        if (branch && zero) begin
            pc_next = branch_target;
        end else if (jump && alu_src) begin
            pc_next = jalr_target & ~32'b1;
        end else if (jump) begin
            pc_next = jal_target;
        end else begin
            pc_next = pc + 4;
        end
    end

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

    // Memory interface
    assign mem_addr       = alu_result;
    assign mem_write_data = reg_data2;

endmodule
