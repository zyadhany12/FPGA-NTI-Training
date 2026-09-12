`timescale 1ps/1ps
module top_module
(
    input  wire clk_top, in_top, rst_top, 
    output wire [3:0] falling_count_top,rising_count_top,
    output wire [6:0] R,
    output wire [6:0] R_C,
    output wire [6:0] F,
    output wire [6:0] F_C,
    output wire [6:0] T,
    output wire [6:0] T_C
);

wire updated_clk;
wire [3:0] total_count;
wire falling_tick_top ;
wire rising_tick_top;

clk_divider clock
(
    .in_clk(clk_top),
    .rst(rst_top),
    .clk_out(updated_clk)
);


Edge_Detector detector
(
    .clk(updated_clk),
    .level(in_top),
    .rst(rst_top),
    .rising_tick(rising_tick_top),
    .falling_tick(falling_tick_top)
);


edge_counter counter
(
    .clk(updated_clk),
    .rst(rst_top),
    .Falling_tick(falling_tick_top),
    .Rising_tick(rising_tick_top),
    .Rising_count(rising_count_top),
    .Falling_count(falling_count_top),
    .Total_count(total_count)
);



_6xSevenSegment  display
(
    .rst(rst_top),
    .rise_count(rising_count_top),
    .fall_count(falling_count_top),
    .total(total_count),
    .R(R),
    .R_C(R_C),
    .F(F),
    .F_C(F_C),
    .T(T),
    .T_C(T_C)
);

endmodule



module top_module_tb;
    reg clk_top, in_top, rst_top;
    wire [3:0] falling_count_top,rising_count_top;
    wire [6:0] R;
    wire [6:0] R_C;
    wire [6:0] F;
    wire [6:0] F_C;
    wire [6:0] T;
    wire [6:0] T_C;


top_module dut(.*);

always  #5 clk_top = ~clk_top;
always  #400 in_top = ~in_top;

initial 
begin
    clk_top = 0;
    rst_top = 0;
    in_top  = 0;

    $monitor("Time: %0t || rst: %b || in: %b || R: %b || R_C: %b || F: %b || F_C: %b || T: %b || T_C: %b",
              $time, rst_top, in_top, R, R_C, F, F_C, T, T_C);
    
    #10;
    rst_top = 1; 

    #600;
    rst_top = 0;
    #20;
    rst_top = 1;
    #600;
    $finish;
end

endmodule