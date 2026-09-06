module RAM (
    input wire RS, WS, Enable, clock,
    input wire [15:0] Data_input,
    input wire [5:0] Address,  //64 => 6 
    output reg [15:0] Data_Output
);

    reg [15:0] ram_memory [0:63];
always @(posedge clock)
    begin
      if (Enable == 1) 
      begin
        if(RS == 1 && WS != 1)
        begin
            Data_Output = ram_memory[Address];
        end
        else if(WS == 1 && RS != 1)
        begin
            ram_memory[Address]  = Data_input;
        end
        else if(WS == 1 && RS == 1)
        begin
            
        end
      end
    end
endmodule 

module tb_RAM;

reg  tb_RS;
reg  tb_WS;
reg  tb_Enable;
reg  tb_clock;
reg  [15:0] tb_Data_input;
reg  [5:0] tb_address;
wire [15:0] tb_Data_output;


RAM dut
(
    .RS(tb_RS),
    .WS(tb_WS),
    .Enable(tb_Enable),
    .clock(tb_clock),
    .Data_input(tb_Data_input),
    .Data_Output(tb_Data_output),
    .Address(tb_address)
);

initial begin
    tb_clock = 1'b0;
    forever begin
        #5 tb_clock = ~tb_clock;
    end
end
initial 
    begin
            $monitor("RS=%b, WS=%b, Enable=%b, Data Input =%b Data Output =%b", 
            tb_RS, tb_WS, tb_Enable, tb_Data_input, tb_Data_output);


        //test 2
            tb_RS = 0; tb_WS = 1; tb_address = 6'b001100; tb_Data_input = 16'b0000111100001111; tb_Enable = 1;
            #10;
        //test 1
            tb_RS = 0; tb_WS = 0; tb_address = 6'b001100; tb_Data_input = 16'b0110110101111010 ; tb_Enable = 1;
            #10;
        //test 3
            tb_RS = 1; tb_WS = 0; tb_address = 6'b001100; tb_Data_input = 16'b1100001100110011; tb_Enable = 1;
            #10;
        //test 4
            tb_RS = 1; tb_WS = 1; tb_address = 6'b001100; tb_Data_input = 16'b0101101010101010; tb_Enable = 1;
            #10;
        //test 5
            tb_RS = 1; tb_WS = 1; tb_address = 6'b001100; tb_Data_input = 16'b0011001100110011; tb_Enable = 0;
            #10;

            $finish;
    end
endmodule