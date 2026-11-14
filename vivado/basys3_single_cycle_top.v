// Basys3 bring-up wrapper for the maintained single-cycle CPU.
//
// DEBUG_MODE = 1:
//   The CPU advances at a slow clock-enable rate and the switches select
//   internal values shown on LEDs and the seven-segment display.
//
// DEBUG_MODE = 0:
//   The CPU advances every 100 MHz clock cycle. Counters expose the
//   performance run through the same display interface.
//
// This is an FPGA wrapper. Its ROM initialization uses $readmemh, which is
// suitable for Vivado FPGA inference but is not part of the Innovus source.
module basys3_single_cycle_top #(
    parameter integer DEBUG_MODE = 1,
    parameter integer DEBUG_DIV_BITS = 25,
    parameter integer IMEM_DEPTH = 1024,
    parameter integer DMEM_DEPTH = 1024,
    parameter integer PERF_LIMIT = 0,
    parameter IMEM_FILE = ""
) (
    input  wire        clk,
    input  wire        btnC,
    input  wire [15:0] sw,
    output reg  [15:0] led,
    output reg  [6:0]  seg,
    output reg  [3:0]  an,
    output wire        dp
);
    reg [31:0] imem [0:IMEM_DEPTH-1];
    reg [31:0] dmem [0:DMEM_DEPTH-1];
    integer i;

    reg [DEBUG_DIV_BITS-1:0] debug_divider;
    reg [31:0] cycle_count;
    reg [31:0] instruction_count;
    reg [31:0] store_count;
    reg        perf_done;

    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire [3:0]  dmem_wstrb;
    wire        dmem_re;
    wire        dmem_we;
    wire        debug_tick;
    wire        cpu_enable;
    wire [3:0]  display_select;
    reg  [31:0] display_value;

    reg [17:0] refresh_count;
    reg [3:0]  display_nibble;

    initial begin
        for (i = 0; i < IMEM_DEPTH; i = i + 1)
            imem[i] = 32'b0;
        for (i = 0; i < DMEM_DEPTH; i = i + 1)
            dmem[i] = 32'b0;
        if (IMEM_FILE != "")
            $readmemh(IMEM_FILE, imem);
    end

    assign imem_rdata = (imem_addr[1:0] == 2'b00 &&
                         imem_addr[31:2] < IMEM_DEPTH) ?
                        imem[imem_addr[31:2]] : 32'b0;

    assign dmem_rdata = (dmem_re && dmem_addr[31:2] < DMEM_DEPTH) ?
                        dmem[dmem_addr[31:2]] : 32'b0;

    assign debug_tick = (debug_divider == {DEBUG_DIV_BITS{1'b0}});
    assign cpu_enable = (DEBUG_MODE != 0) ? debug_tick : !perf_done;
    assign display_select = sw[3:0];
    assign dp = 1'b1;

    cpu u_cpu (
        .clk(clk),
        .reset(btnC),
        .enable(cpu_enable),
        .instruction(imem_rdata),
        .mem_read_data(dmem_rdata),
        .pc(imem_addr),
        .mem_addr(dmem_addr),
        .mem_write_data(dmem_wdata),
        .mem_write_strobe(dmem_wstrb),
        .mem_read(dmem_re),
        .mem_write(dmem_we)
    );

    always @(posedge clk) begin
        if (btnC) begin
            debug_divider <= {DEBUG_DIV_BITS{1'b0}};
            cycle_count <= 32'b0;
            instruction_count <= 32'b0;
            store_count <= 32'b0;
            perf_done <= 1'b0;
            refresh_count <= 18'b0;
        end else begin
            debug_divider <= debug_divider + 1'b1;
            refresh_count <= refresh_count + 1'b1;
            if (cpu_enable) begin
                cycle_count <= cycle_count + 1'b1;
                instruction_count <= instruction_count + 1'b1;
                if (dmem_we)
                    store_count <= store_count + 1'b1;
                if (DEBUG_MODE == 0 && PERF_LIMIT != 0 &&
                    cycle_count >= PERF_LIMIT - 1)
                    perf_done <= 1'b1;
            end
        end
    end

    always @(posedge clk) begin
        if (dmem_we && dmem_addr[31:2] < DMEM_DEPTH) begin
            if (dmem_wstrb[0]) dmem[dmem_addr[31:2]][7:0] <= dmem_wdata[7:0];
            if (dmem_wstrb[1]) dmem[dmem_addr[31:2]][15:8] <= dmem_wdata[15:8];
            if (dmem_wstrb[2]) dmem[dmem_addr[31:2]][23:16] <= dmem_wdata[23:16];
            if (dmem_wstrb[3]) dmem[dmem_addr[31:2]][31:24] <= dmem_wdata[31:24];
        end
    end

    always @* begin
        case (display_select)
            4'd0: display_value = imem_addr;
            4'd1: display_value = imem_rdata;
            4'd2: display_value = dmem_addr;
            4'd3: display_value = dmem_wdata;
            4'd4: display_value = cycle_count;
            4'd5: display_value = instruction_count;
            4'd6: display_value = store_count;
            4'd7: display_value = dmem_rdata;
            default: display_value = 32'h0000_0000;
        endcase
        led = display_value[15:0];
    end

    always @* begin
        case (refresh_count[17:16])
            2'd0: begin an = 4'b1110; display_nibble = display_value[3:0]; end
            2'd1: begin an = 4'b1101; display_nibble = display_value[7:4]; end
            2'd2: begin an = 4'b1011; display_nibble = display_value[11:8]; end
            default: begin an = 4'b0111; display_nibble = display_value[15:12]; end
        endcase
        case (display_nibble)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'ha: seg = 7'b0001000;
            4'hb: seg = 7'b0000011;
            4'hc: seg = 7'b1000110;
            4'hd: seg = 7'b0100001;
            4'he: seg = 7'b0000110;
            default: seg = 7'b0001110;
        endcase
    end
endmodule
