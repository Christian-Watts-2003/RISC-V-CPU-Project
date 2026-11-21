// Basys3-compatible CPU timing-isolation wrapper.
//
// Unlike cpu_timing_test_top, this version keeps instruction and load data
// internal so it can be implemented on the board without exceeding the
// package I/O limit. The switches drive both buses and keep the CPU logic
// dependent on top-level inputs during timing analysis.
module cpu_timing_board_top (
    input  wire        clk,
    input  wire        btnC,
    input  wire [15:0] sw,
    output wire [15:0] led
);
    wire [31:0] instruction = {sw, sw};
    wire [31:0] mem_read_data = {sw, sw};
    wire [31:0] pc;
    wire [31:0] mem_addr;
    wire [31:0] mem_write_data;
    wire [3:0]  mem_write_strobe;
    wire        mem_read;
    wire        mem_write;

    cpu u_cpu (
        .clk(clk),
        .reset(btnC),
        .enable(1'b1),
        .instruction(instruction),
        .mem_read_data(mem_read_data),
        .pc(pc),
        .mem_addr(mem_addr),
        .mem_write_data(mem_write_data),
        .mem_write_strobe(mem_write_strobe),
        .mem_read(mem_read),
        .mem_write(mem_write)
    );

    assign led = pc[15:0] ^
                 mem_addr[15:0] ^
                 mem_write_data[15:0] ^
                 {12'b0, mem_write_strobe};
endmodule
