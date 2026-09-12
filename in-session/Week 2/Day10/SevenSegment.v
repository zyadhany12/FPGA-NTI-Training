module _6xSevenSegment
#(parameter  input_width = 4, parameter output_width = 7)
(
    input wire [input_width - 1: 0] rise_count, fall_count, total,
    input  wire rst,
    output reg [output_width - 1: 0] R, R_C, F, F_C, T, T_C
);

always @(*) 
begin    
    if(!rst)
    begin
        R   = 7'h48;
        R_C = 7'h40; 
        F   = 7'h87;
        F_C = 7'h40;
        T   = 7'h7F;
        T_C = 7'h40;
    end
    else
    begin
        R   = 7'h08;      
        F   = 7'h0E;      
        T   = 7'h07;
        
        case(rise_count)
            0: R_C = 7'h40;
            1: R_C = 7'h79;
            2: R_C = 7'h24;
            3: R_C = 7'h30;
            4: R_C = 7'h19;
            5: R_C = 7'h12;
            6: R_C = 7'h02;
            7: R_C = 7'h78;
            8: R_C = 7'h00;
            9: R_C = 7'h10;
            default: R_C = 7'h7F;
        endcase
        
        case(fall_count - 1'b1) 
            0: F_C = 7'h40;
            1: F_C = 7'h79;
            2: F_C = 7'h24;
            3: F_C = 7'h30;
            4: F_C = 7'h19;
            5: F_C = 7'h12;
            6: F_C = 7'h02;
            7: F_C = 7'h78;
            8: F_C = 7'h00;
            9: F_C = 7'h10;
            default: F_C = 7'h7F;
        endcase
        
        case(total)
            0: T_C = 7'h40;
            1: T_C = 7'h79;
            2: T_C = 7'h24;
            3: T_C = 7'h30;
            4: T_C = 7'h19;
            5: T_C = 7'h12;
            6: T_C = 7'h02;
            7: T_C = 7'h78;
            8: T_C = 7'h00;
            9: T_C = 7'h10;
            default: T_C = 7'h7F;
        endcase
    end
end

endmodule