`timescale 1ns / 1ps

module debounce #( 
    parameter clk_period = 20, 
    parameter required_delay = 100
)(
    input wire sw, 
    input wire clk, 
    input wire rst,
    output reg db
);

    localparam [2:0] Zero    = 3'b000, 
                     wait1_1 = 3'b001,
                     wait1_2 = 3'b010,
                     wait1_3 = 3'b011,
                     one     = 3'b100,   
                     wait0_1 = 3'b101,
                     wait0_2 = 3'b110,
                     wait0_3 = 3'b111;
                     
    reg [2:0] current_state, next_state;
    reg [3:0] counter, increment;
    
    localparam target = (required_delay / clk_period) ;
    wire m_tick;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            counter <= 0;
            current_state <= Zero;
        end else begin
            counter <= increment;
            current_state <= next_state;
        end
    end

    always @(*) begin
        if(counter == target) begin
            increment = 0;
        end else begin
            increment = counter + 1;
        end
    end

    assign m_tick = (counter == target) ? 1'b1 : 1'b0;

    always @(*) begin
        db = 1'b0;
        next_state = current_state;
        
        case(current_state)
            Zero   : if(sw) next_state = wait1_1; else next_state = Zero;
            wait1_1: if(sw & m_tick) next_state = wait1_2; else if(!sw) next_state = Zero; else if(sw & !m_tick) next_state = wait1_1;
            wait1_2: if(sw & m_tick) next_state = wait1_3; else if(!sw) next_state = Zero; else if(sw & !m_tick) next_state = wait1_2;
            wait1_3: if(sw & m_tick) next_state = one; else if(!sw) next_state = Zero; else if(sw & !m_tick) next_state = wait1_3;
            one    : if(!sw) next_state = wait0_1; else next_state = one;
            wait0_1: if(!sw & m_tick) next_state = wait0_2; else if(!sw & !m_tick) next_state = wait0_1; else if(sw) next_state = one;
            wait0_2: if(!sw & m_tick) next_state = wait0_3; else if(!sw & !m_tick) next_state = wait0_2; else if(sw) next_state = one;
            wait0_3: if(!sw & m_tick) next_state = Zero; else if(!sw & !m_tick) next_state = wait0_3; else if(sw) next_state = one;
        endcase
        
        if(current_state == one || current_state == wait0_1 || current_state == wait0_2 || current_state == wait0_3) begin
            db = 1'b1;
        end
    end
endmodule 


module debounce_tb;
    reg sw, clk, rst;
    wire db;

    debounce button(
        .sw(sw),
        .clk(clk),
        .rst(rst),
        .db(db)
    );

    always #10 clk = ~clk;

initial begin
        clk = 0;
        sw = 0;
        rst = 0;
        
        $monitor("Time: %0t  ||  sw: %b || rst: %b  || db: %b", $time, sw, rst, db);

        #15 rst = 1;

        #100;
        sw = 1; #10; 
        sw = 0; #15; 
        sw = 1; #5; 
        sw = 0; #20;  
        
        sw = 1; 
        #500; 
        
        sw = 0; #12;  
        sw = 1; #15;  
        sw = 0; #8;  
        sw = 1; #20;  
        
        sw = 0; 
        #500; 

        $finish;
    end
endmodule