//00_00_00_00 => hg_fe_dc_ba 
        // 0 =>  11_00_00_00 => 0xC0
        // 1 =>  11_11_10_01 => 0xF9
        // 2 =>  10_10_01_00 => 0xA4
        // 3 =>  10_11_00_00 => 0xB0
        // 4 =>  10_01_01_01 => 0x95
        // 5 =>  10_01_00_10 => 0x92
        // 6 =>  10_00_00_10 => 0x82
        // 7 =>  11_11_10_00 => 0xF8
        // 8 =>  10_00_00_00 => 0x80
        // 9 =>  10_01_00_00 => 0x90
        // A =>  10_00_10_00 => 0x88
        // b =>  10_00_00_11 => 0x83
        // C =>  11_00_01_10 => 0xC6
        // d =>  10_10_00_01 => 0xA1
        // E =>  10_00_01_10 => 0x86
        // F =>  10_00_11_10 => 0x8E

module SevenSegment
#(parameter  input_width = 4, parameter output_width = 8)
(
    input wire [input_width - 1: 0] in,
    output reg [output_width - 1: 0] out
);
always @(*) begin    
    case(in)
        0: out = 8'hC0;
        1: out = 8'hF9;
        2: out = 8'hA4;
        3: out = 8'hB0;
        4: out = 8'h99;
        5: out = 8'h92;
        6: out = 8'h82;
        7: out = 8'hF8;
        8: out = 8'h80;
        9: out = 8'h90;
        10: out = 8'h88;
        11: out = 8'h83;
        12: out = 8'hC6;
        13: out = 8'hA1;
        14: out = 8'hA1;
        15: out = 8'h8E;
        default: out = 8'hFF;
    endcase
end

endmodule 


module SevenSegment_tb;
localparam  input_width_tb = 4;
localparam  output_width_tb = 8;
reg [input_width_tb - 1: 0] in_tb;
wire [output_width_tb - 1: 0] out_tb;

SevenSegment #(.output_width(output_width_tb), .input_width(input_width_tb))
dut (
    .in(in_tb),
    .out(out_tb)
);


initial begin
    
    $monitor("Input: %d || Output(Hex): %h || Output(Binary): %b", in_tb, out_tb, out_tb);

    in_tb = 0;
    #10;
    in_tb = 1;
    #10;
    in_tb = 2;
    #10;
    in_tb = 3;
    #10;
    in_tb = 4;
    #10;
    in_tb = 5;
    #10;
    in_tb = 6;
    #10;
    in_tb = 7;
    #10;
    in_tb = 8;
    #10;
    in_tb = 9;
    #10;
    in_tb = 10;
    #10;
    in_tb = 11;
    #10;
    in_tb = 12;
    #10;
    in_tb = 13;
    #10;
    in_tb = 14;
    #10;
    in_tb = 15;
    #10;
end


endmodule 