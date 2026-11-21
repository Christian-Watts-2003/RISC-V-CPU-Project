module fetch_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] imem_rdata,
    input  wire        hold_pc,
    input  wire        hold_ifid,
    input  wire        flush_ifid,
    input  wire        redirect,
    input  wire [31:0] redirect_pc,
    output reg  [31:0] pc,
    output reg         ifid_valid,
    output reg  [31:0] ifid_pc,
    output reg  [31:0] ifid_instr
);

    // Synchronous active-high reset. PC redirection has priority over hold;
    // IF/ID flush has priority over hold so wrong-path instructions are dropped.
    always @(posedge clk) begin
        if (rst) begin
            pc         <= 32'b0;
            ifid_valid <= 1'b0;
        end else begin
            if (redirect)
                pc <= redirect_pc;
            else if (!hold_pc)
                pc <= pc + 32'd4;

            if (flush_ifid) begin
                ifid_valid <= 1'b0;
            end else if (!hold_ifid) begin
                ifid_pc    <= pc;
                ifid_instr <= imem_rdata;
                ifid_valid <= 1'b1;
            end
        end
    end
endmodule
