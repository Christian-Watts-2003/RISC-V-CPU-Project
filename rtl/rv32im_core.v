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

    // Pipeline state registers. These are placeholders for the full five-stage
    // implementation described in docs/SPEC.md. The valid bits allow bubbles to
    // be represented without retiring instructions.
    reg [31:0] pc;
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_instr;
    reg [31:0] ex_mem_pc;
    reg [31:0] ex_mem_instr;
    reg [31:0] mem_wb_pc;
    reg [31:0] mem_wb_instr;

    reg        if_id_valid;
    reg        id_ex_valid;
    reg        ex_mem_valid;
    reg        mem_wb_valid;

    // Placeholder hold/stall signals. These will be replaced by the hazard unit
    // and forwarding logic in later steps.
    wire       fetch_hold = 1'b0;
    wire       decode_stall = 1'b0;

    // Core fetch address is the current PC.
    assign imem_addr = pc;
    assign dmem_addr = 32'b0;
    assign dmem_wdata = 32'b0;
    assign dmem_wstrb = 4'b0000;
    assign dmem_re = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            pc          <= 32'b0;
            if_id_pc    <= 32'b0;
            if_id_instr <= 32'b0;
            id_ex_pc    <= 32'b0;
            id_ex_instr <= 32'b0;
            ex_mem_pc   <= 32'b0;
            ex_mem_instr<= 32'b0;
            mem_wb_pc   <= 32'b0;
            mem_wb_instr<= 32'b0;

            if_id_valid <= 1'b0;
            id_ex_valid <= 1'b0;
            ex_mem_valid<= 1'b0;
            mem_wb_valid<= 1'b0;
        end else begin
            // IF stage: advance the PC unless the fetch stage is stalled.
            if (!fetch_hold)
                pc <= pc + 32'd4;

            // IF/ID: capture the current instruction and PC.
            if (!decode_stall) begin
                if_id_pc    <= pc;
                if_id_instr <= imem_rdata;
                if_id_valid <= 1'b1;
            end else begin
                if_id_valid <= 1'b0;
            end

            // The remaining pipeline registers are advanced as a placeholder
            // representation of the five-stage design. Full EX/MEM/WB behavior is
            // added in later implementation steps.
            id_ex_pc    <= if_id_pc;
            id_ex_instr <= if_id_instr;
            id_ex_valid <= if_id_valid;

            ex_mem_pc   <= id_ex_pc;
            ex_mem_instr<= id_ex_instr;
            ex_mem_valid<= id_ex_valid;

            mem_wb_pc   <= ex_mem_pc;
            mem_wb_instr<= ex_mem_instr;
            mem_wb_valid<= ex_mem_valid;
        end
    end

endmodule
