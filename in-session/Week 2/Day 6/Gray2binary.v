//1) save the most siginificant bit
//2) MSB + (MSB - 1) => sum
//3) sum + (MSB - 2) => sum => repeat


module Gray2binary
#( parameter width = 8 )
(
    input wire [width - 1: 0] in,
    output reg [width - 1: 0] out
);
integer i;
always @(*) begin
    out[width-1] = in[width-1];
    for(i = width - 1; i > 0; i = i -1)
    begin
        out[i - 1] = out[i] ^ in[i-1];
    end
end
endmodule



module Gray2binary_tb;
localparam width_tb = 8;
reg [width_tb - 1: 0] in_tb;
wire [width_tb - 1: 0] out_tb;

Gray2binary #(.width(width_tb))
dut
(
    .in(in_tb),
    .out(out_tb)
);


initial begin
    
    
    $monitor("Input: %b || Output: %b", in_tb, out_tb);

    in_tb = 1010;
    #10
    in_tb = 1110;
    #10
    in_tb = 1011;
    #10
    in_tb = 0010;
    #10
    in_tb = 1000;
    #10
    in_tb = 1111;
    #10
    in_tb = 0000;
    #10
    in_tb = 0110;
    #10
    $finish;
end


endmodule 