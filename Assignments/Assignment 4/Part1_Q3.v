module tb;
wire [3:0] data = 4'b10X1;
wire [3:0] ref = 4'b1001;
wire [3:0] A = 4'b1010;
wire [3:0] B = 4'b0101;
wire [3:0] C = 4'b1100;
wire flag = /*x*/ ^data ==  /*0*/(data === ref)/**/ ? 1'b1 : 1'b0; //1- reduce XOR => 2- the equality terms // flag = 1'b1 & 1'b0 = 1'bx
wire [3:0] Y = (A + B << 1 > C) ? A ^ B : A | B;  // 1-A+B() => 2- AB << 1 => 3-AB<<1 > => 4-(TRUE) A XOR B / 4- (FALSE) A OR B
wire [7:0] Result = { /*000*/{3{^C}}, /*1*/|B,/*1*/ ~&A, A[2:1] }; //0000_1101
initial begin
$display("flag = %b, Y = %b, Result = %b", flag, Y, Result); // flag = x || Y = 4'b1111 || Result = 8'b0000_1101
end
endmodule
