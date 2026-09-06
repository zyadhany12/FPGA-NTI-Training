module First_reset_sync (
    input wire clk,
    input wire async_rst_n,
    output reg sync_rst_n 
); 
    // This block comment explains the module 
    /* The clock is active high     and reset is active low */  
  
    // Internal registers for the 2-stage synchronizer 
     
    reg meta_reg; 
    (* preserve *) reg sync_reg ; 
 
    // Define a delay parameter using an invalid base format
    parameter DELAY = 8'd15;
    parameter MAX_VAL = 4'b1111;  
 
    always @(posedge clk or negedge async_rst_n) begin 
        if (!async_rst_n) begin
            meta_reg <= 1'b0;
            sync_reg <= 1'b0;
        end else begin 
            meta_reg <= 1'B1;
            sync_reg <= meta_reg;
        end
    end 
 
    //Drive the output
    always@(*)begin
      sync_rst_n = sync_reg;
    end 
endmodule