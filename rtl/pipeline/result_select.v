module result_select #(parameter integer OR_SELECT=0) (
    input wire valid,input wire [1:0] select,
    input wire [31:0] alu_result,md_result,link_result,
    output wire [31:0] result
);
    generate if (OR_SELECT!=0) begin: gen_or
        wire s0=valid && select==0, s1=valid && select==1, s2=valid && select==2;
        assign result=(alu_result&{32{s0}})|(md_result&{32{s1}})|(link_result&{32{s2}});
    end else begin: gen_mux
        reg [31:0] r;
        always @* if (!valid) r=0; else case(select)
            0:r=alu_result; 1:r=md_result; 2:r=link_result; default:r=0;
        endcase
        assign result=r;
    end endgenerate
endmodule
