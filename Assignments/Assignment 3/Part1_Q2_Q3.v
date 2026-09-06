/*
for a shared common bus using 'Z' is more efficient as 0 and 1 alone make conflicts when receiving signals from different devices.
while 'Z' disconnects from idle devices, allowing only one device to connect at the same time.
*/

module Tristate
(
    inout wire [7:0] bus,
    output  wire [7:0] Output,
    input wire [7:0] tx_data,
    input wire tx_enable
);
assign bus = tx_enable ? tx_data : 8'bzz_zz_zz_zz;

assign Output = bus;
endmodule





// Question 3
/*

wire => can be assigned continuosly using "assign". and its defualt in simulation is 'X'  while in verilog/HDL it defualts to 'Z'.
reg  => can be assigned in procedural blocks (ex. always @(), ). and it defaults to 'X'. 

*/