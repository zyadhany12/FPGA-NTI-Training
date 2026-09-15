module Top_Module_tb;
reg clk_tb, rst_tb, Serial_input_tb;
wire moore_Sequence_overlap_tb, mealy_Sequence_overlap_tb;
wire [2:0] moore_counter_overlap_tb, mealy_counter_overlap_tb;
wire moore_Sequence_nonoverlap_tb, mealy_Sequence_nonoverlap_tb;

Top_Module dut (
    .clk(clk_tb),
    .rst(rst_tb),
    .Serial_input(Serial_input_tb),
    .moore_Sequence_overlap(moore_Sequence_overlap_tb),
    .mealy_Sequence_overlap(mealy_Sequence_overlap_tb),
    .moore_counter_overlap(moore_counter_overlap_tb),
    .mealy_counter_overlap(mealy_counter_overlap_tb),
    .moore_Sequence_nonoverlap(moore_Sequence_nonoverlap_tb),
    .mealy_Sequence_nonoverlap(mealy_Sequence_nonoverlap_tb)
);

always #5 clk_tb = ~clk_tb;

initial begin
    clk_tb = 0;
    Serial_input_tb = 0;
    rst_tb = 0;
    #15;
    rst_tb = 1;

    $monitor("Time: %0t || Serial_In: %b || Overlap  Moore: %b Mealy: %b Cnt_M: %d Cnt_Me: %d || NonOverlap Moore: %b Mealy: %b"
             ,$time, Serial_input_tb,
             moore_Sequence_overlap_tb, mealy_Sequence_overlap_tb,
             moore_counter_overlap_tb, mealy_counter_overlap_tb,
             moore_Sequence_nonoverlap_tb, mealy_Sequence_nonoverlap_tb);

    // basic match: 1 1 0 1 0 1
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;

    // second match right after, same pattern
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;

    // partial pattern, no match
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 0;
    @(negedge clk_tb); Serial_input_tb = 1;

    // extra 1s to stress Second/Fourth backtrack, then reset mid-sequence
    @(negedge clk_tb); Serial_input_tb = 1;
    @(negedge clk_tb); Serial_input_tb = 1;
    rst_tb = 0;
    @(negedge clk_tb); rst_tb = 1;

    // pattern again after reset
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