module memory_ctrl 
( 
    input wire [7:0] data_in,
    output reg [0:15] addr_bus, 
    inout  wire [7:0]data_bus,
    input wire clk
);   

wire [31:0] full_word;
reg [7:0] grid_mem [0:3][0:1];
reg  [4:0] start_idx; 
 // Operation A 
 always  @(*)
    begin  
        grid_mem[0][0] = 8'hFF;       
        // Operation B 
        grid_mem[1][2] = 8'h00;  
         // Operation C
        addr_bus[0:3]  = full_word[start_idx +: 4];
    end 
endmodule 
