module Top_Module
(
    input wire clk, Serial_input, rst,
    output wire moore_Sequence_overlap, mealy_Sequence_overlap,
    output wire [2:0] moore_counter_overlap, mealy_counter_overlap,
    output wire moore_Sequence_nonoverlap, mealy_Sequence_nonoverlap
);

overlapping overlap_inst (
    .clk(clk),
    .rst(rst),
    .Serial_input(Serial_input),
    .moore_Sequence_detector(moore_Sequence_overlap),
    .mealy_Sequence_detector(mealy_Sequence_overlap),
    .moore_counter(moore_counter_overlap),
    .mealy_counter(mealy_counter_overlap)
);

non_overlapping nonoverlap_inst (
    .clk(clk),
    .rst(rst),
    .Serial_input(Serial_input),
    .moore_Sequence_detector(moore_Sequence_nonoverlap),
    .mealy_Sequence_detector(mealy_Sequence_nonoverlap)
);

endmodule