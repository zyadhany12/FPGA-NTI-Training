module clk_divider
#(parameter Ratio = 32'd16) 
(
    input wire in_clk,
    input wire rst,
    output reg clk_out 
);

    reg [31:0] counter; 

    always @(posedge in_clk or negedge rst) 
    begin
        if (rst == 0) 
        begin
            counter <= 32'd0;
            clk_out <= 1'b0;
        end 
        else begin
            if (counter >= Ratio - 1) 
            begin
                counter <= 32'd0;
                clk_out <= 1'b1; 
            end 
            else begin
                counter <= counter + 1'b1;
                clk_out <= 1'b0; 
            end
        end
    end
endmodule



module clk_divider_tb;
reg in_clk_tb;
reg rst_tb;
wire clk_out_tb;
localparam Ratio_tb = 32'd16;

clk_divider #(.Ratio(Ratio_tb))
dut (
    .in_clk(in_clk_tb),
    .clk_out(clk_out_tb),
    .rst(rst_tb)
);

always #5 in_clk_tb = ~in_clk_tb;

initial 
begin
    in_clk_tb = 0;
    rst_tb = 1;
    $monitor("Time: %0t || Clock: %b || Counter: ",$time, clk_out_tb, dut.counter);
    #10;
    rst_tb = 0;
    #10;
    rst_tb = 1;

    #100000;
    $finish;
end





endmodule 