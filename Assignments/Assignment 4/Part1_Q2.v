module tb;
reg [3:0] active_lanes = 4'b0100;
reg [3:0] fault_masks =  4'b0010;
wire [3:0] mask_enable_logical = (active_lanes && fault_masks);
wire [3:0] mask_enable_bitwise = (active_lanes & fault_masks);
initial 
begin
    $display("Mask Enable Logical: %b", mask_enable_logical); //=> 1 (it evaluates the whole number as one returning one bit value so it sees active lanes > 0 and fault masks > 0 so it returns 1)
    $display("Mask Enable Bitwise: %b", mask_enable_bitwise); //=> 0 (it compares each position independently returning 4'b0000)
end
endmodule


// logical expressions are more dangerous as they do not express equality as much as just approving that both are greater than 0, and if intended to make an AND gate it causes a logical error