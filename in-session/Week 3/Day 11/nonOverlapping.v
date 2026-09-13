module non_overlapping
(
    input wire clk, Serial_input, rst,
    output reg moore_Sequence_detector, mealy_Sequence_detector
);



localparam  start  = 3'b000;
localparam  First  = 3'b001;
localparam  Second = 3'b010;
localparam  Third  = 3'b011;
localparam  Fourth = 3'b100;
localparam  Fifth  = 3'b101;
localparam  Sixth  = 3'b110;

reg [2:0] moore_current_state, moore_next_state;
reg [2:0] mealy_current_state, mealy_next_state;


always @(posedge clk or negedge rst) 
begin
    if(!rst)
    begin
        moore_current_state <= start;
        mealy_current_state <= start;
        moore_Sequence_detector <= 1'b0;
        mealy_Sequence_detector <= 1'b0;
    end
    else
    begin
    moore_current_state <= moore_next_state;
    mealy_current_state <= mealy_next_state;
    end
end

//moore  110101
always @(*) 
begin
    case (moore_current_state)
    start:  if(Serial_input)  moore_next_state = First;  else moore_next_state = start;
    First:  if(Serial_input)  moore_next_state = Second; else moore_next_state = start;
    Second: if(!Serial_input) moore_next_state = Third;  else moore_next_state = start;
    Third:  if(Serial_input)  moore_next_state = Fourth; else moore_next_state = start;
    Fourth: if(!Serial_input) moore_next_state = Fifth;  else moore_next_state = start;
    Fifth:  if(Serial_input)  moore_next_state = Sixth;  else moore_next_state = start;
    Sixth:                    moore_next_state = start;
    default: moore_next_state = start;
    endcase
    if(moore_current_state == Sixth)
    begin
        moore_Sequence_detector = 1'b1;
    end
end

// Mealy
always @(*) 
begin
    case (mealy_current_state)
    start:  if(Serial_input)   mealy_next_state = First;  else mealy_next_state = start;
    First:  if(Serial_input)   mealy_next_state = Second; else mealy_next_state = start;
    Second: if(!Serial_input)  mealy_next_state = Third;  else mealy_next_state = start;
    Third:  if(Serial_input)   mealy_next_state = Fourth; else mealy_next_state = start;
    Fourth: if(!Serial_input)  mealy_next_state = Fifth;  else mealy_next_state = start;
    Fifth:                     mealy_next_state = start;
    default: moore_next_state = start;
    endcase
    if((mealy_current_state == Fifth) && (Serial_input))
    begin
        mealy_Sequence_detector = 1'b1;
    end
end



endmodule



module non_overlapping_tb;
reg clk_tb, rst_tb, Serial_input_tb;
wire moore_Sequence_detector_tb, mealy_Sequence_detector_tb;

non_overlapping dut (
    .clk(clk_tb),
    .rst(rst_tb),  
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
    
    $monitor("Time: %0t || Serial_In: %b || moore_Sequence: %b || Mealy_Sequence: %b "
             ,$time, Serial_input_tb, moore_Sequence_detector_tb, mealy_Sequence_detector_tb);
    
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
    @(negedge clk_tb);
    #20;
    $finish;
end

endmodule