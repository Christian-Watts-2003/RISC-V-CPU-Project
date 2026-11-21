module result_select #(
    parameter integer OR_SELECT = 0
) (
    input  wire        valid,
    input  wire [1:0]  select,
    input  wire [31:0] alu_result,
    input  wire [31:0] md_result,
    input  wire [31:0] link_result,
    output wire [31:0] result
);
    generate
        if (OR_SELECT != 0) begin : gen_or_select
            wire sel_alu = valid && (select == 2'd0);
            wire sel_md   = valid && (select == 2'd1);
            wire sel_link = valid && (select == 2'd2);
            assign result = (alu_result & {32{sel_alu}}) |
                            (md_result  & {32{sel_md}}) |
                            (link_result & {32{sel_link}});
        end else begin : gen_mux_select
            reg [31:0] result_mux;
            always @* begin
                if (!valid) result_mux = 32'b0;
                else case (select)
                    2'd0: result_mux = alu_result;
                    2'd1: result_mux = md_result;
                    2'd2: result_mux = link_result;
                    default: result_mux = 32'b0;
                endcase
            end
            assign result = result_mux;
        end
    endgenerate
endmodule
