module grid_mem_router #(parameter WORD_WIDTH = 8)
(
    input wire clk,
    input wire rst,
    input wire oe,
    input wire endian_swap,
    input wire [1:0] row_addr,
    input wire col_address,
    output reg [31:0] processing_word,
    output reg [7:0] bus_data 
);

reg [7:0] fabric_mem [3:0][1:0];


always @(*) 
begin
    if(oe)
    begin
        bus_data = fabric_mem[row_addr][col_address];
    end
    else 
    begin
        output = 8'bz;
    end
end

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        processing_word = 32'd0;
    end
    else 
    begin
    for(integer i = 0; i < 4; i = i + 1)
    begin
        if(endian_swap == 0)
        begin
            processing_word[(i * 8) +: 8] <= memory[i][0];
        end
        else if(endian_swap == 1)
        begin
            processing_word[(31 -(i*8)) -: 8] <= memory[i][0];
        end
    end
    end
end
endmodule