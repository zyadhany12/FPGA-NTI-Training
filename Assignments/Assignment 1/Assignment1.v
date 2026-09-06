// 1. THE SOLUTION USING PRIMITIVES
// module Full_Adder
// (
//     input  wire A,
//     input  wire B,
//     input  wire cin,
//     output wire sum,
//     output wire carry 
// );
// 
// assign sum = (A ^ B) ^ cin;
// assign carry = (A & B) | (cin & (A ^ B));
// 
// endmodule 



// 2. THE SOLUTION USING HALF ADDERS 
module Half_Adder
(
    input  wire A,
    input  wire B,
    output wire C,
    output wire Sum
);

assign Sum = A ^ B;
assign C   = A & B;

endmodule 

module Full_Adder
(
    input  wire A, B, cin,
    output wire sum, carry
);

    wire sum1;
    wire carry1;
    wire carry2;

Half_Adder Half_1
(
    .A(A),
    .B(B),
    .Sum(sum1),
    .C(carry1)
);

Half_Adder Half_2
(
    .A(cin),
    .B(sum1),
    .Sum(sum),
    .C(carry2)
);

 assign carry = carry1 | carry2;
endmodule 


// 3. THE SOLUTION USING BEHAVIORAL BLOCK
// module Full_Adder
// (
//     input  wire A, B, cin,
//     output reg  sum, carry
// );
// 
// // with "Always" use reg ..... with "Assign" use wire 
// always @(*) 
//     begin
//         {carry, sum} = A + B + cin;
//     end
// 
// endmodule 




                                // THE TEST BENCH IS DOWN BELOW
module tb_Full_Adder;

reg  tb_A;
reg  tb_B;
reg  tb_cin;
wire tb_sum;
wire tb_carry;

Full_Adder dut(
    .A(tb_A),
    .B(tb_B),
    .cin(tb_cin),
    .sum(tb_sum),
    .carry(tb_carry)
);

initial begin
        $monitor("A=%b, B=%b, cin=%b | Sum=%b, Carry=%b",tb_A, tb_B, tb_cin, tb_sum, tb_carry);
        
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