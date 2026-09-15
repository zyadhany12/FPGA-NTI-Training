module register
#( parameter WIDTH = 8 )
(
    input clk,
    input rst,
    input load,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

always @(posedge clk or posedge rst) 
begin
    if (rst) data_out <= 'b0;
    else 
    if(load) data_out <= data_in;
    else if(!load) data_out <= data_out;
end
endmodule