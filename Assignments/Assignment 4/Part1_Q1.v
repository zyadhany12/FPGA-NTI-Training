module test_shift;
  wire signed [3:0] a = 4'sb1010;
  wire [7:0] result;
  assign result = $signed({2{a}}) >>> 2;
  initial begin
    $display("Result: %b", result);  // Display the result in binary format
    // the result without the $signed => 00_101_010       //with it  => 11_101_010
  end
endmodule
