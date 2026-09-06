module fulladder_gatelevel
(
    input wire A_gl,
    input wire B_gl,
    input wire cin_gl,
    output wire result_gl,
    output wire cout_gl
);


assign result_gl = cin_gl ^ (A_gl ^ B_gl);
assign  cout_gl  =  (A_gl & B_gl)  | ((A_gl^B_gl) & cin_gl);

endmodule 




module Half_Adder
(
    input A_h, B_h,
    output result_h, cout_h
);

assign result_h = A_h ^ B_h;
assign  cout_h  = A_h & B_h;

endmodule 
module fulladder_structlevel
(
    input  wire A_sl, B_sl, cin_sl,
    output wire result_sl, cout_sl
);

    wire result;
    wire carry;
    wire carry1;

Half_Adder Half_1
(
    .A_h(A_sl),
    .B_h(B_sl),
    .result_h(result),
    .cout_h(carry)
);
Half_Adder Half_2
(
    .A_h(cin_sl),
    .B_h(result),
    .result_h(result_sl),
    .cout_h(carry1)
);

assign cout_sl =  carry | carry1;

endmodule


module fulladder_behavlevel
(
    input  wire A_bl, B_bl, cin_bl,
    output reg  result_bl, cout_bl
);

always @(*) 
    begin
        {cout_bl, result_bl} = A_bl + B_bl + cin_bl;
    end

endmodule




module tb_fulladder;

reg  tb_A;
reg  tb_B;
reg  tb_cin;

wire tb_result_gl;
wire tb_cout_gl;

wire tb_result_sl;
wire tb_cout_sl;


wire tb_result_bl;
wire tb_cout_bl;


fulladder_gatelevel dut_gl(
    .A_gl(tb_A),                 
    .B_gl(tb_B),                 
    .cin_gl(tb_cin),             
    .result_gl(tb_result_gl), 
    .cout_gl(tb_cout_gl)
);

fulladder_structlevel dut_sl(
    .A_sl(tb_A),
    .B_sl(tb_B),
    .cin_sl(tb_cin),
    .result_sl(tb_result_sl),
    .cout_sl(tb_cout_sl)
);

fulladder_behavlevel dut_bl(
    .A_bl(tb_A),
    .B_bl(tb_B),
    .cin_bl(tb_cin),
    .result_bl(tb_result_bl),
    .cout_bl(tb_cout_bl)
);


initial begin
        $monitor("A=%b, B=%b, cin=%b | Sum_gl=[%b,%b], Sum_sl=[%b,%b], Sum_bl=[%b,%b]"
        ,tb_A, tb_B, tb_cin, tb_result_gl, tb_cout_gl, tb_result_sl, tb_cout_sl, tb_result_bl, tb_cout_bl);
        
        // Test case 1: 0 + 0 + 0
        tb_A = 0; tb_B = 0; tb_cin = 0;
        #10; 
        
        // Test case 2: 1 + 0 + 0
        tb_A = 1; tb_B = 0; tb_cin = 0;
        #10;
        
        // Test case 3: 1 + 1 + 0
        tb_A = 1; tb_B = 1; tb_cin = 0;
        #10;
        
        // Test case 4: 1 + 1 + 1
        tb_A = 1; tb_B = 1; tb_cin = 1;
        #10;

    end
endmodule