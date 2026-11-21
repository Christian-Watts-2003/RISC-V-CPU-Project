/**
 * OR-gated execution-result selection variant.
 *
 * Optimization rationale and relationship to the paper:
 * - The design goal discussed in the paper is to shorten the instruction's
 *   combinational control/data path by exposing useful decode information early
 *   and allowing independent datapath work to proceed in parallel.
 * - This variant applies that idea at the execution-result selection point:
 *   ALU and M-extension results are computed on separate combinational paths,
 *   then independently masked with mutually exclusive enables and combined by
 *   bitwise OR. This replaces the priority selection between those two results
 *   with one-hot gating; jump and load writeback choices remain higher-level
 *   writeback selections, as in the baseline.
 * - `use_muldiv` is a small combinational predecode from the current instruction
 *   fields plus the existing control input. It qualifies the M-extension path
 *   before selection and prevents an unrelated opcode/funct7 combination from
 *   enabling it. This is not a new registered predecode pipeline stage and
 *   does not add a cycle or change the external interface.
 * - Keep this module separate from the baseline `datapath` so identical tests
 *   can compare functionally equivalent implementations. The OR-gated form is
 *   an architectural experiment inspired by the paper's parallelism/timing
 *   motivation; whether it improves FPGA timing or resources must be confirmed
 *   after synthesis and timing analysis for the target device and constraints.
 */
module datapath_or (
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

    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [31:0] reg_data1;
    logic [31:0] reg_data2;
    logic [31:0] writeback_data;
    logic [31:0] imm;
    logic [31:0] alu_result;
    logic [31:0] muldiv_result;
    logic [31:0] alu_selected;
    logic [31:0] muldiv_selected;
    logic [31:0] execution_result;
    logic        illegal_op;
    logic        muldiv_valid;
    logic        use_muldiv;
    logic        alu_result_enable;
    logic        muldiv_result_enable;
    logic [31:0] pc_plus_4;
    logic [31:0] branch_target;
    logic [31:0] jal_target;
    logic [31:0] jalr_target;
    logic [31:0] pc_next;

    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign rd  = instruction[11:7];

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

    imm_gen datapath_imm_gen (
        .instruction (instruction),
        .imm_src     (imm_src),
        .imm_value   (imm)
    );

    alu datapath_alu (
        .a          (reg_data1),
        .b          (alu_src ? imm : reg_data2),
        .alu_op     (alu_op),
        .result     (alu_result),
        .zero       (zero),
        .illegal_op (illegal_op)
    );

    // Early combinational qualification for the parallel M-extension path.
    // It uses fields already present in the instruction; it is not a pipeline
    // register/stage, so it preserves the baseline single-cycle timing model.
    // The controller's `is_muldiv` is retained as an enable, while the opcode
    // and funct7 checks make the local path selection self-qualifying.
    assign use_muldiv = is_muldiv &&
                        (instruction[6:0] == 7'b0110011) &&
                        (instruction[31:25] == 7'b0000001);

    muldiv datapath_muldiv (
        .clk        (clk),
        .reset      (reset),
        .start      (use_muldiv),
        .muldiv_op  (muldiv_op),
        .a          (reg_data1),
        .b          (reg_data2),
        .result     (muldiv_result),
        .valid      (muldiv_valid)
    );

    // Parallel-result selection (the main OR-gating experiment):
    // 1. The ALU and M-extension unit produce candidate results independently.
    // 2. Their decode enables are complementary, so only the selected bus is
    //    allowed through; the other is forced to zero.
    // 3. OR combines the masked buses without allowing the unselected unit to
    //    contaminate the result. This is logically equivalent to a 2:1 mux.
    // The enables must remain mutually exclusive for that equivalence to hold.
    assign muldiv_result_enable = use_muldiv;
    assign alu_result_enable    = ~use_muldiv;
    assign alu_selected         = alu_result    & {32{alu_result_enable}};
    assign muldiv_selected      = muldiv_result & {32{muldiv_result_enable}};
    assign execution_result     = alu_selected | muldiv_selected;

    // These address/control calculations are kept independent of the result
    // selection to preserve parallel combinational evaluation of next-PC paths.
    assign pc_plus_4     = pc + 32'd4;
    assign branch_target = pc + imm;
    assign jal_target    = pc + imm;
    assign jalr_target   = reg_data1 + imm;

    // The existing writeback priority is deliberately retained: link address
    // for jumps, memory data for loads, otherwise the OR-selected execution
    // result. This isolates the optimization being tested from unrelated muxes.
    always_comb begin
        if (jump)
            writeback_data = pc_plus_4;
        else if (mem_read)
            writeback_data = mem_read_data;
        else
            writeback_data = execution_result;
    end

    // Branch/JAL/JALR target candidates are calculated above in parallel;
    // this control selection chooses the architecturally required next PC.
    always_comb begin
        if (branch && zero)
            pc_next = branch_target;
        else if (jump && alu_src)
            pc_next = jalr_target & 32'hFFFF_FFFE;
        else if (jump)
            pc_next = jal_target;
        else
            pc_next = pc_plus_4;
    end

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 32'b0;
        else
            pc <= pc_next;
    end

    assign mem_addr       = alu_result;
    assign mem_write_data = reg_data2;

endmodule
