module encoder #(
    parameter Input_Width  = 8,
    parameter Output_Width = 3
) (
    input  wire [ Input_Width - 1:0] A,
    input wire en,
    output reg  [Output_Width - 1:0] B
);

  reg value;
  integer i;

  always @(*) begin
    if (en) 
    begin
      begin : loop
        for (i = 0; i < Input_Width; i = i + 1) begin
          if (A[i] == 1) begin
            B = i[Output_Width - 1:0];
            disable loop;
          end
        end
      end
    end
    else 
    begin
        B = 0;
    end
  end
endmodule



module tb_encoder;
  localparam Input_Width_tb = 8;
  localparam Output_Width_tb = 3;
  reg  [ Input_Width_tb - 1:0] tb_A;
  reg tb_en;
  wire [Output_Width_tb - 1:0] tb_B;


  encoder #(
      .Input_Width (Input_Width_tb),
      .Output_Width(Output_Width_tb)
  ) dut (
      .A(tb_A),
      .en(tb_en),
      .B(tb_B)
  );

  initial begin
    $monitor("Input: %b || Output: %b", tb_A, tb_B);

    tb_A = 1;tb_en = 0;
    #10;
    tb_A = 0;tb_en = 1;
    #10;
    tb_A = 1;tb_en = 1;
    #10;
    tb_A = 2;tb_en = 1;
    #10;
    tb_A = 4;tb_en = 1;
    #10;
    tb_A = 8;tb_en = 1;
    #10;
    tb_A = 16;tb_en = 1;
    #10;
    tb_A = 32;tb_en = 1;
    #10;
    tb_A = 64;tb_en = 1;
    #10;
    tb_A = 128;tb_en = 1;
    #10;
    $finish;
  end

endmodule
