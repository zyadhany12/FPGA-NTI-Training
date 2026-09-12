`timescale 1ns/1ps
module Edge_Detector
(
    input wire clk, level, rst,
    output reg rising_tick, falling_tick
);

localparam state0 = 2'b00;
localparam state_edge = 2'b01;
localparam state1 = 2'b10;

reg  [1:0] rising_current_state, falling_current_state;
reg  [1:0] rising_next_state, falling_next_state;
 
 always @(posedge clk or negedge rst) 
 begin
    if(!rst)
    begin
    rising_current_state <= state0;
    falling_current_state <= state0;
    end
    else
    begin
    rising_current_state <= rising_next_state;
    falling_current_state <= falling_next_state;
    end
 end
 


// moore
always @(*)  
begin
    case (rising_current_state)
    state0:     if(level == 1) rising_next_state = state_edge;
    state_edge: if(level == 1) rising_next_state = state1;  else rising_next_state = state0;
    state1:     if(level == 1) rising_next_state = state1; else rising_next_state = state0;
    default: rising_next_state = state0;
    endcase 
    if(rising_current_state == state_edge)
    begin
        rising_tick = 1'b1;
    end
    else 
    begin
        rising_tick = 1'b0;
    end
end

// falling moore
always @(*)  
begin
    falling_tick = 1'b0;
    case (falling_current_state)
    state0:     if(level == 0) falling_next_state = state_edge;
    state_edge: if(level == 0) falling_next_state = state1;  else falling_next_state = state0;
    state1:     if(level == 0) falling_next_state = state1; else falling_next_state = state0;
    default: falling_next_state = state0;
    endcase 
    if(falling_current_state == state_edge)
    begin
        falling_tick = 1'b1;
    end
    else 
    begin
        falling_tick = 1'b0;
    end
end

endmodule


module Edge_Detector_tb;
    reg clk; 
    reg level; 
    reg rst;
    wire rising_tick;
    wire falling_tick;


Edge_Detector dut(.*);

    always  #5 clk = ~clk;
    always #100 level = ~level; 
initial 
begin
    clk = 0;
    level = 0;
    rst = 1'b0; 

    $monitor("Time: %0t || Level: %b || rst: %b || falling_Value: %b || rising: %b", 
              $time, level, rst, falling_tick, rising_tick);

    #30;
    rst = 1'b1; 
    
    #300;
    $finish; 
end
endmodule 