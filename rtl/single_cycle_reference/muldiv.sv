/** Archived single-cycle combinational RV32M unit. */
module muldiv (
    input logic clk, reset, start,
    input logic [2:0] muldiv_op,
    input logic [31:0] a,b,
    output reg [31:0] result,
    output wire valid
);
    reg signed [63:0] prod_signed;
    reg [63:0] prod_unsigned;
    reg signed [64:0] prod_su;
    always @* begin
        prod_signed=$signed(a)*$signed(b);
        prod_unsigned=a*b;
        prod_su=$signed({a[31],a})*$signed({1'b0,b});
        case (muldiv_op)
            3'b000: result=prod_signed[31:0];
            3'b001: result=prod_signed[63:32];
            3'b010: result=prod_su[63:32];
            3'b011: result=prod_unsigned[63:32];
            3'b100: if (b==0) result=32'hFFFFFFFF;
                     else if (a==32'h80000000 && b==32'hFFFFFFFF) result=32'h80000000;
                     else result=$signed(a)/$signed(b);
            3'b101: result=(b==0)?32'hFFFFFFFF:a/b;
            3'b110: if (b==0) result=a;
                     else if (a==32'h80000000 && b==32'hFFFFFFFF) result=0;
                     else result=$signed(a)%$signed(b);
            3'b111: result=(b==0)?a:a%b;
            default: result=0;
        endcase
    end
    assign valid=start;
endmodule
