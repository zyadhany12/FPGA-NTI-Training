module Data_Scramble 
(
    input wire [7:0] data_in,
    input wire [1:0] op_mode,
    input wire [1:0] scramble_key,
    input wire sleep_mode,
    output reg [7:0] data_out,
    output reg parity_err,
    output reg is_zero 
);


always @(*) 
begin
    if(sleep_mode)
    begin
        data_out = 8'b0000_0000;
        parity_err = 0;
        is_zero = 0;
    end
    else if(!sleep_mode)
    begin
        case(op_mode)
            2'b00: data_out = data_in;
            2'b01: data_out = data_in^{4{scramble_key}};
            2'b10: data_out = {{2{data_in[7]}} , data_in[5:0]};
            2'b11: data_out = {data_in[3:0], data_in[7:4]};
        endcase
        parity_err = ~^data_in;
        is_zero = !data_out;
    end
end

endmodule



module tb_Data_Scramble;

    reg [7:0] tb_data_in;
    reg [1:0] tb_op_mode;
    reg [1:0] tb_scramble_key;
    reg tb_sleep_mode;
    
    wire [7:0] tb_data_out;
    wire tb_parity_err;
    wire tb_is_zero;

    Data_Scramble dut (
        .data_in(tb_data_in),
        .op_mode(tb_op_mode),
        .scramble_key(tb_scramble_key),
        .sleep_mode(tb_sleep_mode),
        .data_out(tb_data_out),
        .parity_err(tb_parity_err),
        .is_zero(tb_is_zero)
    );

    initial begin
        $monitor("Sleep=%b | OpMode=%b | DataIn=%b | Key=%b || Out=%b | ParErr=%b | isZero=%b", 
                 tb_sleep_mode, tb_op_mode, tb_data_in, tb_scramble_key, tb_data_out, tb_parity_err, tb_is_zero);

        tb_sleep_mode = 1'b1;
        tb_op_mode = 2'b11;        
        tb_data_in = 8'b1111_1111;  
        tb_scramble_key = 2'b10;
        #10;

        tb_sleep_mode = 1'b0;
        #10;

        tb_op_mode = 2'b00;
        tb_data_in = 8'b1010_0100; 
        #10;

        tb_op_mode = 2'b01;
        tb_data_in = 8'b1100_1100;
        tb_scramble_key = 2'b10; 
        #10;

        tb_data_in = 8'b1011_0100; 
        #10;

        tb_op_mode = 2'b10;
        tb_data_in = 8'b0111_0100; 
        #10;

        tb_op_mode = 2'b11;
        tb_data_in = 8'b1101_0000; 
        #10;

        tb_op_mode = 2'b00;
        tb_data_in = 8'b0000_0000; 
        #10;

        $finish;
    end

endmodule