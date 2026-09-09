module alu
#(
  parameter WIDTH = 8
)
(
  input wire [WIDTH - 1: 0] in_a,
  input wire [WIDTH - 1: 0] in_b,
  input wire [2:0] opcode,
  input wire a_is_zero,
  output reg [WIDTH - 1: 0] alu_out
);

assign a_is_zero = in_a == 0 ? 1'b1: 1'b0;
always @(*) 
begin
  case (opcode)
    3'd0: alu_out = in_a;
    3'd1: alu_out = in_a;
    3'd2: alu_out = in_a + in_b;
    3'd3: alu_out = in_a & in_b;
    3'd4: alu_out = in_a ^ in_b;
    3'd5: alu_out = in_b;
    3'd6: alu_out = in_a;
    3'd7: alu_out = in_a;
  endcase

end
endmodule



module alu_test;

  localparam WIDTH=8;

  localparam PASS0=0, PASS1=1, ADD=2, AND=3, XOR=4, PASSB=5, PASS6=6, PASS7=7;

  reg  [      2:0] opcode    ;
  reg  [WIDTH-1:0] in_a      ;
  reg  [WIDTH-1:0] in_b      ;
  wire             a_is_zero ;
  wire [WIDTH-1:0] alu_out   ;


  alu
  #(
    .WIDTH ( WIDTH )
   )
  alu_inst
   (
    .opcode    ( opcode    ),
    .in_a      ( in_a      ),
    .in_b      ( in_b      ),
    .a_is_zero ( a_is_zero ),
    .alu_out   ( alu_out   ) 
   );

  task expect;
    input             exp_zero;
    input [WIDTH-1:0] exp_out;
    if (a_is_zero !== exp_zero || alu_out !== exp_out) begin
      $display("TEST FAILED");
      $display("At time %0d opcode=%b in_a=%b in_b=%b a_is_zero=%b alu_out=%b",
               $time, opcode, in_a, in_b, a_is_zero, alu_out);
      if (a_is_zero !== exp_zero)
        $display("a_is_zero should be %b", exp_zero);
      if (alu_out !== exp_out)
        $display("alu_out should be %b", exp_out);
      $finish;
    end
   else begin
     $display("At time %0d opcode=%b in_a=%b in_b=%b a_is_zero=%b alu_out=%b",
               $time, opcode, in_a, in_b, a_is_zero, alu_out);
   end
  endtask

  initial begin
    opcode=PASS0; in_a=8'h42; in_b=8'h86; #1 expect (1'b0, 8'h42);
    opcode=PASS1; in_a=8'h42; in_b=8'h86; #1 expect (1'b0, 8'h42);
    opcode=ADD;   in_a=8'h42; in_b=8'h86; #1 expect (1'b0, 8'hC8);
    opcode=AND;   in_a=8'h42; in_b=8'h86; #1 expect (1'b0, 8'h02);
    opcode=XOR;   in_a=8'h42; in_b=8'h86; #1 expect (1'b0, 8'hC4);
    opcode=PASSB; in_a=8'h42; in_b=8'h86; #1 expect (1'b0, 8'h86);
    opcode=PASS6; in_a=8'h42; in_b=8'h86; #1 expect (1'b0, 8'h42);
    opcode=PASS7; in_a=8'h42; in_b=8'h86; #1 expect (1'b0, 8'h42);
    opcode=PASS7; in_a=8'h00; in_b=8'h86; #1 expect (1'b1, 8'h00);
    $display("TEST PASSED");
    $finish;
  end


endmodule
