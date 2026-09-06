//  1
input wire [15:0] A;
assign A =  16'hFF0A;

//  2
input wire [7:0] B;
assign B = 8'bxxxxzzzz;


//  3   unsized => assign without specifiying size?
input wire [11:0] C;
assign C = 4096;
assign C = 'd4096;


//  4
input wire [3:0] D;
assign D = 4'b1011; // -8 +3


//  5
input wire [11:0] F;
assign F = -4096;
assign F = -'d4096


//  6 
real G;
always@(*)
begin
    G = 1.25E-4;
end


//  7  
real bi;
always @(*) begin
    bi = 3.141592653589793;
end


//  8
// 10 => 10 - 8 => 1 & '2' // 1 / 8 => 0 & '1' 
input wire [3:0] H;
assign H = 4'o21;