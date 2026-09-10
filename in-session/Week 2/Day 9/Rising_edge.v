`timescale 1ns/1ps
module Rising_Detector
(
    input wire clk, level, rst,
    output reg moore_tick, mealy_tick
);

localparam state0 = 2'b00;
localparam state_edge = 2'b01;
localparam state1 = 2'b10;

reg  [1:0] moore_current_state, mealy_current_state;
reg  [1:0] moore_next_state, mealy_next_state;
 
 always @(posedge clk or negedge rst) 
 begin
    if(!rst)
    begin
    moore_current_state <= state0;
    mealy_current_state <= state0;
    end
    else
    moore_current_state <= moore_next_state;
    mealy_current_state <= mealy_next_state;
 end
 


// moore
always @(*)  
begin
    case (moore_current_state)
    state0:     if(level == 1) moore_next_state = state_edge;
    state_edge: if(level == 1) moore_next_state = state1;  else moore_next_state = state0;
    state1:     if(level == 1) moore_next_state = state1; else moore_next_state = state0;
    default: moore_next_state = state0;
    endcase 
    if(moore_current_state == state_edge)
    begin
        moore_tick = 1'b1;
    end
    else 
    begin
        moore_tick = 1'b0;
    end
end

// mealy
always @(*)  
begin
    case (mealy_current_state)
    state0:     if(level == 1) mealy_next_state = state_edge;
    state1:     if(level == 1) mealy_next_state = state1; else mealy_next_state = state0;
    default: mealy_next_state = state0;
    endcase 

    if((mealy_current_state == state0) && (level == 1'b1))
    begin
        mealy_tick = 1'b1;
    end
    else 
    begin
        mealy_tick = 1'b0;
    end
end

endmodule


module Rising_Detector_tb;
    reg clk; 
    reg level; 
    reg rst;
    wire moore_tick;
    wire mealy_tick;


Rising_Detector dut(.*);

    always  #5 clk = ~clk;
    always #100 level = ~level; 
initial 
begin
    clk = 0;
    level = 0;
    rst = 1'b0; 

    $monitor("Time: %0t || Level: %b || rst: %b || Moore_Value: %b || Mealy: %b", 
              $time, level, rst, moore_tick, mealy_tick);

    #15;
    rst = 1'b1; 
    
    #500;
    $finish; 
end
endmodule 