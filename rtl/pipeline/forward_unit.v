module forward_unit (
    input wire ex_valid, input wire [4:0] ex_rs1,ex_rs2,
    input wire exmem_valid,exmem_reg_write,exmem_is_load,
    input wire [4:0] exmem_rd,
    input wire memwb_valid,memwb_reg_write,input wire [4:0] memwb_rd,
    output reg [1:0] forward_a,forward_b
);
    always @* begin
        forward_a=0; forward_b=0;
        if (ex_valid && exmem_valid && exmem_reg_write && !exmem_is_load && exmem_rd!=0 && exmem_rd==ex_rs1) forward_a=1;
        else if (ex_valid && memwb_valid && memwb_reg_write && memwb_rd!=0 && memwb_rd==ex_rs1) forward_a=2;
        if (ex_valid && exmem_valid && exmem_reg_write && !exmem_is_load && exmem_rd!=0 && exmem_rd==ex_rs2) forward_b=1;
        else if (ex_valid && memwb_valid && memwb_reg_write && memwb_rd!=0 && memwb_rd==ex_rs2) forward_b=2;
    end
endmodule
