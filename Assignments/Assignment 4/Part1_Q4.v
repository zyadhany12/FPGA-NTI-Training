module conditional_trick (
    input  wire a,
    input  wire sel,
    input  wire b,
    output wire out_ternary,
    output reg  out_if
);
  // Implementation 1: Conditional (Ternary) Operator
  assign out_ternary = sel ? a : b;
  // Implementation 2: If-Else Statement
  always @(*) begin
    if (sel) out_if = a;
    else out_if = b;
  end
endmodule



module tb_conditional_trick;
  reg tb_a;
  reg tb_sel;
  reg tb_b;
  wire tb_out_ternary;
  wire  tb_out_if;


conditional_trick dut
(
  .a(tb_a),
  .sel(tb_sel),
  .b(tb_b),
  .out_ternary(tb_out_ternary),
  .out_if(tb_out_if)
);



initial 
begin
$monitor("A=%b, B=%b, Sel=%b | Out Ternary=%b, Out_if=%b",tb_a, tb_b, tb_sel, tb_out_ternary, tb_out_if);

tb_a = 1'b1; tb_b = 1'b0; tb_sel = 1'bx;
#10
tb_a = 1'b1; tb_b = 1'b1; tb_sel = 1'bx;

// A=1, B=0, Sel=x | Out Ternary=x, Out_if=0
// A=1, B=1, Sel=x | Out Ternary=1, Out_if=1
end


endmodule