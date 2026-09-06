module ALU 
(
    input wire [5:0] A,
    input wire [5:0] B,
    input wire Cin,
    input wire [2:0] Control,
    output reg [5:0] Output,
    output reg cout
);

always @(*)
begin
    Output = 6'b0000_00;
    cout = 1'b0;
    case(Control)
        3'b000: {cout , Output} = A + B + Cin;
        3'b001: {cout , Output} = A - B - Cin;
        3'b010: Output =  (Cin == 0) ? A : B;  
        3'b011: Output = -A;
        3'b100: Output = A ^ B;
        3'b101: Output = (A==B) ? 1 : 0;
        3'b110: Output = { 1'b0, A[5:1]};
        3'b111: Output = {A[4:0], 1'b0};
    endcase
end

endmodule 



module tb_ALU;

    reg [5:0] tb_A;
    reg [5:0] tb_B;
    reg tb_Cin;
    reg [2:0] tb_Control;
    
    wire [5:0] tb_Output;
    wire tb_cout;
    
    ALU dut (
        .A(tb_A),
        .B(tb_B),
        .Cin(tb_Cin),
        .Control(tb_Control),
        .Output(tb_Output),
        .cout(tb_cout)
    );
    
    initial begin
        $display("Control | A  | B  | Cin | Out | Cout");
        $monitor("%b    | %d | %d |  %b  |  %d |  %b", 
                tb_Control, tb_A, tb_B, tb_Cin, tb_Output, tb_cout);
                 
        tb_A = 6'd15;
        tb_B = 6'd10;
        tb_Cin = 1'b0;
        

        tb_Control = 3'b000; #10; 
        tb_Control = 3'b001; #10; 
        
        tb_Control = 3'b010; tb_Cin = 1'b0; #10; 
        tb_Control = 3'b010; tb_Cin = 1'b1; #10; 
        
        tb_Control = 3'b011; #10;
        tb_Control = 3'b100; #10; 
        
        tb_Control = 3'b101; tb_A = 6'd10; #10; 
        tb_A = 6'd15; 
        
        tb_Control = 3'b110; #10; 
        tb_Control = 3'b111; #10; 
        
        $finish;
    end
endmodule