// parameterized 10-bit shift reg => clk, rst Asynchronous (active low), hold_n synchronous(active low), out 10-bit
// rotate reg -> when rst => set(1000_0000_00) => until (0000_0000_01) => then rst
// if hold_n  -> holds the one at location-n in the reg;


module lightChaser
#(parameter  reg_width = 10)
(
    input wire clk,
    input wire rst,
    input wire hold_n,      //should be initialized by (reg_width - 1) then change as wished
    output reg [reg_width - 1: 0] out
);

always @(posedge clk or negedge rst) begin
    if (rst == 0) begin
        out = {1'b1, {(reg_width - 1){1'b0}}} ; 
    end 
    else if(hold_n) begin
        if (out == {{reg_width-1{1'b0}}, 1'b1}) begin
            out <= 1'b1 << (reg_width - 1); 
        end 
        else begin
            out <= out >> 1; 
        end
    end
end
    
endmodule

module lightChaser_tb;
localparam reg_width_tb = 10;
reg clk_tb;
reg hold_n_tb;
reg rst_tb;
wire [reg_width_tb - 1: 0]out_tb;


lightChaser #( .reg_width(reg_width_tb))
dut (
    .clk(clk_tb),
    .hold_n(hold_n_tb),
    .rst(rst_tb),
    .out(out_tb)
);

always #5 clk_tb = ~clk_tb;
initial begin
        clk_tb = 0;
        rst_tb = 0;
        $monitor("Time: %0t | rst: %b | out: %b", $time, rst_tb, out_tb);        
        #10 rst_tb = 0;
        #10 rst_tb = 1; 
        $finish;
end

endmodule