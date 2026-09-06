module decoder
#(parameter Input_Width = 3, parameter Output_Width = 8)
(
    input wire [Input_Width - 1: 0] A,
    input wire en,
    output reg [Output_Width - 1: 0] B
);

always @(*)
begin
    if(en)
    begin
    B = 0;
    B[A] = 1'b1;
    end
end
endmodule



module tb_decoder;
localparam Input_Width_tb = 3;
localparam Output_Width_tb = 8;
reg [Input_Width_tb - 1: 0] tb_A;
reg tb_en;
wire [Output_Width_tb - 1: 0] tb_B;


decoder #(.Input_Width(Input_Width_tb), .Output_Width(Output_Width_tb))
dut 
(
    .A(tb_A),
    .en(tb_en),
    .B(tb_B)
);

initial 
begin
    $monitor("Input: %b/%d || Output: %b",tb_A, tb_A, tb_B);

    tb_A = 0; en = 0;
    #10;
    tb_A = 1; en = 1;
    #10;
    tb_A = 2;en = 1;
    #10;
    tb_A = 3;en = 1;
    #10;
    tb_A = 4;en = 1;
    #10;
    tb_A = 5;en = 1;
    #10;
    tb_A = 6;en = 1;
    #10;
    tb_A = 7;en = 1;
    #10;
    $finish;
end

endmodule