module edge_counter
(
    input wire clk,
    input wire rst,
    input wire Falling_tick, Rising_tick,       
    output reg  [3:0] Falling_count, Rising_count, 
    output wire [3:0] Total_count 
);

    always @(posedge clk or negedge rst) 
    begin
        if (!rst) 
        begin
            Falling_count <= 4'b0; 
            Rising_count  <= 4'b0; 
        end 
        else 
        begin
            if (Falling_tick) 
            begin
                Falling_count <= Falling_count + 1'b1;
            end
            
            if (Rising_tick) 
            begin
                Rising_count <= Rising_count + 1'b1;
            end
        end
    end

    assign Total_count = Rising_count + Falling_count;

endmodule