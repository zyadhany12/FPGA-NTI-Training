module parity
#(parameter serial_width = 8)
(
    input clk, rst, serial_in,
    output reg parity_out, valid
);

reg [serial_width - 1:0] data;
reg [4:0]count;

always @(posedge clk or posedge rst) 
begin
    if(rst)
    begin
        data       <= 'b0;
        count      <= 'b0;
        valid      <= 1'b0;
        parity_out <= 1'b0;
    end
    else
    begin
        if (count < serial_width) begin
            data  <= combine(serial_in, data);
            count <= count + 1'b1;

            if (count == serial_width - 1) begin
                valid <= 1'b1;
                data  <= 'b0;
                count <= 1'b0;
                parity_out <= parity_check(combine(serial_in, data)); 
            end
            else valid <= 1'b0;
        end
    end 
end

function [serial_width - 1:0] combine (input serial_in, input [serial_width - 1:0] data);
    
    combine = (data << 1) | serial_in;
endfunction

function parity_check (input [serial_width - 1:0] data);
    parity_check = ^data;
endfunction





endmodule




module parity_tb;

    reg clk;
    reg rst;
    reg serial_in;
    wire parity_out;
    wire valid;

    parity dut 
    (
        .clk(clk),
        .rst(rst),
        .serial_in(serial_in),
        .parity_out(parity_out),
        .valid(valid)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        serial_in = 0;
        
        $monitor("Time: %0t | Count: %d | Data: %b | Valid: %b | Parity: %b | Seria_in: ", 
                 $time, dut.count, dut.data, valid, parity_out, dut.serial_in);

        #25 rst = 0; 
        serial_in = 1'b1; 
        #20; 
        serial_in = 1'b0; 
        #20; 
        serial_in = 1'b0; 
        #20; 
        serial_in = 1'b1; 
        #20; 
        serial_in = 1'b0; 
        #20; 
        serial_in = 1'b1; 
        #20; 
        serial_in = 1'b0; 
        #20; 
        serial_in = 1'b1; 
        #20; 

        
        $finish;
    end

endmodule