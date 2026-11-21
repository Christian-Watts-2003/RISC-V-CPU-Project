module hazard_unit (
    input wire ifid_valid, input wire [31:0] ifid_instruction,
    input wire idex_valid,idex_is_load, input wire [4:0] idex_rd,
    input wire id_control_flow,ex_redirect,input wire [31:0] ex_redirect_pc,
    input wire md_busy,
    output reg hold_pc,hold_ifid,hold_idex,bubble_idex,bubble_exmem,flush_ifid,redirect,
    output reg [31:0] redirect_pc
);
    wire load_use=ifid_valid && idex_valid && idex_is_load && idex_rd!=0 &&
        ((idex_rd==ifid_instruction[19:15]) || (idex_rd==ifid_instruction[24:20]));
    always @* begin
        hold_pc=0; hold_ifid=0; hold_idex=0; bubble_idex=0; bubble_exmem=0;
        flush_ifid=0; redirect=0; redirect_pc=0;
        if (md_busy) begin hold_pc=1; hold_ifid=1; hold_idex=1; bubble_exmem=1; end
        else if (ex_redirect) begin redirect=1; redirect_pc=ex_redirect_pc; flush_ifid=1; end
        else if (load_use) begin hold_pc=1; hold_ifid=1; bubble_idex=1; end
        else if (ifid_valid && id_control_flow) begin hold_pc=1; flush_ifid=1; end
    end
endmodule
