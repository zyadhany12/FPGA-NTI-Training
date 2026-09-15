
module overlapping_tb;
reg clk_tb, rst_tb, Serial_input_tb;
wire moore_Sequence_detector_tb, mealy_Sequence_detector_tb;
wire [2:0] moore_counter_tb, mealy_counter_tb;
 
overlapping dut (
    .clk(clk_tb),
    .rst(rst_tb),
    .moore_counter(moore_counter_tb),
    .mealy_counter(mealy_counter_tb),
    .Serial_input(Serial_input_tb),
    .moore_Sequence_detector(moore_Sequence_detector_tb),
    .mealy_Sequence_detector(mealy_Sequence_detector_tb)
);
 
always #5 clk_tb = ~clk_tb;
 
initial begin
    clk_tb = 0;
    Serial_input_tb = 0;
    rst_tb = 0;
    #15;
    rst_tb = 1;
 
    $monitor("Time: %0t    || Serial_In: %b || moore_Sequence: %b || Mealy_Sequence: %b || moore_counter: %d || mealy_counter: %d "
             ,$time, Serial_input_tb, moore_Sequence_detector_tb, mealy_Sequence_detector_tb, moore_counter_tb,mealy_counter_tb);
 
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
 
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
 
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
 
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 1;
    rst_tb = 0;
    @(negedge clk_tb); rst_tb = 1;
 
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
 
    #20;
    $finish;
end
 
endmodule