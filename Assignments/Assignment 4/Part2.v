module ALU
(
    input wire [7:0] A,
    input wire [7:0] B,
    input wire [4:0] control,
    input wire cin,
    output reg [15:0] out
);


always @(*) 
begin
    case (control)
        5'd0: out = A + B;
        5'd1:  out = A + B + 1;
        5'd2:  out =  A + ~B + 1;
        5'd3:  out =  A + ~B;
        5'd4:  out =  A+1;
        5'd5:  out =  A-1;
        5'd6:  out =  (A*B) +1;
        5'd7:  out =  A & B;
        5'd8:  out =  A | B;
        5'd9:  out =  A ^ B;
        5'd10:  out =  ~A;
        5'd11:  out =  ~(A & B);
        5'd12:  out =  {A[6:0] , 1'b0};
        5'd13:  out =  A >> B;
        5'd14:  out =  A <<< B ;
        5'd15:  out =  {1'b0 , A[7:1]};
        5'd16:  out =  {A[0], A[7:1]};//ror
        5'd17:  out =  {A[6:0] , A[7]};//ror
        5'd18:  out = A > B ? A : B;
        5'd19:  out = cin == 1 ? B : A;
        5'd20:  out = {~A,~B};
        5'd21:  out =  {A >= B, A > B, A == B, A <= B,  A < B, A != B};
        5'd22:  out =  {A,B};
        default: out = 16'b0;
    endcase
end
endmodule



module tb_ALU;

    reg [7:0] tb_A;
    reg [7:0] tb_B;
    reg [4:0] tb_control;
    reg tb_cin;
    wire [15:0] tb_out;
    
    integer i;

    ALU dut (
        .A(tb_A),
        .B(tb_B),
        .control(tb_control),
        .cin(tb_cin),
        .out(tb_out)
    );

    initial begin
        $monitor("control=%d | A=%b, B=%b, cin=%b | out=%b (Dec: %0d)"
                ,tb_control, tb_A, tb_B, tb_cin, tb_out, tb_out);

        tb_A = 8'd12;  
        tb_B = 8'd5;   
        tb_cin = 1'b0;
        tb_control = 5'd0;

        #10; 

        for (i = 0; i <= 18; i = i + 1) 
        begin
            tb_control = i;
            #10;
        end
        tb_cin = 1'b0; tb_control = 5'd19;
        #10;
        tb_cin = 1'b1; tb_control = 5'd19;
        #10;
        tb_control = 5'd20;
        #10;
        tb_control = 5'd21;
        #10;
        tb_control = 5'd22;
        #10;
        $finish;
    end
endmodule