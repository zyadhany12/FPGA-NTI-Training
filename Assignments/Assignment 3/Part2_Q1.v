module Data_Router 
(
    input wire [31:0] data_in,
    output wire [7:0] byte_low,
    output wire parity_bit,
    output reg [7:0] byte_high
);

assign byte_low = data_in[7:0];
assign parity_bit = data_in[15];

always @(*) 
begin
    byte_high = data_in[31:24];    
end

endmodule