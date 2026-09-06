module reg_file
(
    input wire clk,
    input wire [2:0] read_addr, 
	input wire [2:0] write_addr, 
	input wire [15:0] write_data,
    input wire WE,
    output reg [15:0] read_data,
    output wire [7:0] read_data_top_byte
);

reg[15:0] register_file [7:0] ;


always @(posedge clk) begin
    if(WE)
    begin
        register_file[write_addr] <= write_data;  
    end
end
always @(*) 
begin
    read_data = register_file[read_addr]; 
end 
assign read_data_top_byte = read_data[15:8];

endmodule