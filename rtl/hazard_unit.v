module hazard_unit (
    input  wire        ifid_valid,
    input  wire [31:0] ifid_instruction,
    input  wire        idex_valid,
    input  wire        idex_is_load,
    input  wire [4:0]  idex_rd,
    input  wire        id_control_flow,
    input  wire        ex_redirect,
    input  wire [31:0] ex_redirect_pc,
    input  wire        md_busy,
    output reg         hold_pc,
    output reg         hold_ifid,
    output reg         hold_idex,
    output reg         bubble_idex,
    output reg         bubble_exmem,
    output reg         flush_ifid,
    output reg         redirect,
    output reg  [31:0] redirect_pc
);
    wire load_use = ifid_valid && idex_valid && idex_is_load &&
                    (idex_rd != 5'd0) &&
                    ((idex_rd == ifid_instruction[19:15]) ||
                     (idex_rd == ifid_instruction[24:20]));

    always @* begin
        hold_pc = 1'b0;
        hold_ifid = 1'b0;
        hold_idex = 1'b0;
        bubble_idex = 1'b0;
        bubble_exmem = 1'b0;
        flush_ifid = 1'b0;
        redirect = 1'b0;
        redirect_pc = 32'b0;

        // Multi-cycle execution has priority and freezes all upstream state.
        if (md_busy) begin
            hold_pc = 1'b1;
            hold_ifid = 1'b1;
            hold_idex = 1'b1;
            bubble_exmem = 1'b1;
        end else if (ex_redirect) begin
            redirect = 1'b1;
            redirect_pc = ex_redirect_pc;
            flush_ifid = 1'b1;
        end else if (load_use) begin
            hold_pc = 1'b1;
            hold_ifid = 1'b1;
            bubble_idex = 1'b1;
        end else if (ifid_valid && id_control_flow) begin
            // Let the control-flow instruction enter EX, but discard younger IF.
            hold_pc = 1'b1;
            flush_ifid = 1'b1;
        end
    end
endmodule
