`timescale 1ns/1ps

module i2c_master #(parameter int CLK_FREQ=50_000_000, parameter int I2C_FREQ=100_000) (
    // SystemInterface
    input          clk,
    input          rst_n,

    // Control Interface
    input          start,
    input          rw,
    input   [6:0]  slave_addr,
    input   [7:0]  tx_data,
    input   [31:0] clk_div,

    // Status / Data Interface
    output reg [7:0] rx_data,
    output reg       busy,
    output reg       done,
    output reg       ack_error,
    output reg       bus_error,

    // I2C Bus Interface
    inout         sda,
    inout         scl
);

    // Timing
    reg  [31:0] clk_count;
    reg        i2c_tick;

    // FSM
    typedef enum reg [3:0] {
        IDLE,
        START,
        SEND_ADDR,
        ADDR_ACK,
        WRITE_DATA,
        DATA_ACK,
        READ_DATA,
        MASTER_ACK,
        STOP,
        DONE,
        ERROR
    } state_master;

    state_master state, next_state;

    // Data / Bit Handling
    reg [2:0] bit_count;
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;

    // I2C Open-Drain Control
    reg sda_drive_low;
    reg scl_drive_low;

   //feature option for sending more than one byte or reading
    reg more_data=0;

    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    assign scl = scl_drive_low ? 1'b0 : 1'bz;


//CLOCK DIVIDER
    always @(posedge clk) begin
    if (!rst_n) begin
        clk_count <= 32'd0;
        i2c_tick  <= 1'b0;
    end
    else begin
        if (clk_count == clk_div - 1) begin
            clk_count <= 32'd0;
            i2c_tick  <= 1'b1;
        end
        else begin
            clk_count <= clk_count + 1'b1;
            i2c_tick  <= 1'b0;
        end
    end
end

//CURRENT STATE UPDATING
always @(posedge clk) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end


// SEQUNTIAL LOGIC

always @(posedge clk) begin
    if (!rst_n) begin
        busy          <= 1'b0;
        done          <= 1'b0;
        ack_error     <= 1'b0;
        bus_error     <= 1'b0;

        rx_data       <= 8'd0;
        bit_count     <= 3'd0;
        tx_shift      <= 8'd0;
        rx_shift      <= 8'd0;

        sda_drive_low <= 1'b0;
        scl_drive_low <= 1'b0;
    end
    else begin
         case (state)
             IDLE: begin
                 busy          <= 1'b0;
                 done       <= 1'b0;
                 sda_drive_low <= 1'b0;
                 scl_drive_low <= 1'b0;
                 if (start) begin
                    busy      <= 1'b1;
                    ack_error  <= 1'b0;
                    bus_error  <= 1'b0;
                    tx_shift  <= {slave_addr, rw};
                    rx_shift <= 8'd0;
                    bit_count <= 3'd7;
                 end
             end
             START: begin
                  if (!sda_drive_low) begin
                      // Phase 1: wait for a tick boundary before pulling SDA low
                      if (i2c_tick)
                          sda_drive_low <= 1'b1;   // SDA LOW → START
                  end else begin
                      // Phase 2: hold SDA low for one full tick period (t_HD;STA) before SCL falls
                      if (i2c_tick)
                          scl_drive_low <= 1'b1; // SCL LOW
                  end
            end
            SEND_ADDR: begin
                if(scl_drive_low) begin
                    if(tx_shift[bit_count]==1'b0) begin
                         sda_drive_low <= 1'b1;
                    end
                    else begin
                         sda_drive_low <= 1'b0;
                    end
                    
                    if (i2c_tick) begin
                        scl_drive_low <= 1'b0; // SCL HIGH
                    end

                end else begin
                    if (i2c_tick) begin
                        scl_drive_low <= 1'b1; // SCL LOW
                        if (bit_count != 3'd0) begin
                            bit_count <= bit_count - 1'b1;
                        end
                    end
                end
            end
            ADDR_ACK: begin

                    // Master releases SDA so slave can ACK/NACK
                    sda_drive_low <= 1'b0;

                    if (scl_drive_low) begin
                         // SCL LOW
                             if (i2c_tick)
                                 scl_drive_low <= 1'b0;   // SCL HIGH
                    end else begin
                         // SCL HIGH → sample ACK/NACK
                              if (i2c_tick) begin

                                  if (sda == 1'b1)
                                     ack_error <= 1'b1;
                                  else begin
                                      bit_count <= 3'd7;   // Reset for next byte
                                      if (rw)
                                        rx_shift <= 8'd0;
                                      else
                                        tx_shift <= tx_data;
                                  end

                                 scl_drive_low <= 1'b1;   // SCL LOW
                             end
                     end
            end  
             WRITE_DATA: begin

                     if (scl_drive_low) begin
                        // SCL LOW → put current bit on SDA

                         if (tx_shift[bit_count] == 1'b0)
                               sda_drive_low <= 1'b1;   // Drive LOW → send 0
                         else
                              sda_drive_low <= 1'b0;   // Release → send 1

                         if (i2c_tick)
                              scl_drive_low <= 1'b0;   // SCL HIGH
                     end  else begin
                           // SCL HIGH → slave samples the bit
                          if (i2c_tick) begin
                              scl_drive_low <= 1'b1;   // SCL LOW
                               if (bit_count != 3'd0)
                                      bit_count <= bit_count - 1'b1;
                          end
                     end
             end
             DATA_ACK: begin

                    // Master releases SDA
                    sda_drive_low <= 1'b0;
                    if (scl_drive_low) begin
                        // SCL is LOW
                            if (i2c_tick)
                                 scl_drive_low <= 1'b0;   // Release SCL → HIGH
                    end else begin
                    // SCL is HIGH → sample ACK/NACK
                            if (i2c_tick) begin

                                 if (sda == 1'b1)
                                    ack_error <= 1'b1;   // NACK
                                 else 
                                      bit_count <= 3'd7;

                             scl_drive_low <= 1'b1;   // SCL → LOW
                            end
                     end

             end
             READ_DATA: begin
                     // Master must release SDA
                    sda_drive_low <= 1'b0;
                     if (scl_drive_low) begin
                         // SCL LOW → wait, then raise SCL
                          if (i2c_tick)
                                scl_drive_low <= 1'b0;   // SCL HIGH
                    end else begin
                    // SCL HIGH → sample slave data
                        if (i2c_tick) begin
                               rx_shift[bit_count] <= sda;
                                scl_drive_low <= 1'b1;   // SCL LOW
                                     if (bit_count != 3'd0)
                                            bit_count <= bit_count - 1'b1;
                         end
                    end
             end
             MASTER_ACK: begin
                     rx_data <= rx_shift;       // Complete received byte
                     sda_drive_low <= 1'b0;   // NACK
                     if (scl_drive_low) begin
                           if (i2c_tick)
                                 scl_drive_low <= 1'b0;   // SCL HIGH
                     end else begin
                            if (i2c_tick) begin
                                scl_drive_low <= 1'b1;   // SCL LOW
                                bit_count <= 3'd7;       // reset for future byte
                            end
                    end

             end
            STOP: begin
                      if (scl_drive_low) begin
                          // SCL LOW
                           sda_drive_low <= 1'b1;
                           if (i2c_tick)
                                 scl_drive_low <= 1'b0;
                     end else begin
                          // SCL HIGH
                           if (i2c_tick)
                               sda_drive_low <= 1'b0;  // STOP
                     end
             end
             DONE: begin
                  busy <= 1'b0;
                  done <= 1'b1;
             end
             ERROR: begin
                  busy          <= 1'b0;
                  done          <= 1'b1;
                  bus_error     <= 1'b1;
                  sda_drive_low <= 1'b0;
                  scl_drive_low <= 1'b0;
            end

            default: begin
                busy          <= 1'b0;
                done          <= 1'b0;
                sda_drive_low <= 1'b0;
                scl_drive_low <= 1'b0;
            end

         endcase 
            
    end
end




// FSM COMBINATIONAL UPDATING

always @(*) begin
    
    case (state)
        IDLE: begin
            if (start)
                next_state = START;
            else 
                next_state = IDLE;   
        end
        START: begin
            if (i2c_tick && sda_drive_low) begin
                next_state = SEND_ADDR;
            end else begin
                next_state = START;
            end
        end
        SEND_ADDR: begin
            if (i2c_tick && !scl_drive_low && bit_count==3'd0) begin
                next_state = ADDR_ACK;
            end else begin
                next_state = SEND_ADDR;
            end
        end
        ADDR_ACK: begin
            if (i2c_tick && !scl_drive_low) begin
                if (sda == 1'b1)
                     next_state = STOP;
                else if (rw)
                   next_state = READ_DATA;
                else
                   next_state = WRITE_DATA;
            end else begin
                next_state = ADDR_ACK;
            end
        end
         WRITE_DATA: begin
            if (i2c_tick && !scl_drive_low && bit_count==3'd0) begin
                next_state = DATA_ACK;
            end else begin
                next_state = WRITE_DATA;
            end
        end
          DATA_ACK: begin
            if (i2c_tick && !scl_drive_low) begin
                if (sda == 1'b1)
                    next_state = STOP;
                else
                    next_state = STOP;
            end else begin
                next_state = DATA_ACK;
            end
        end
         READ_DATA: begin
            if (i2c_tick && !scl_drive_low && bit_count == 3'd0)
                  next_state = MASTER_ACK;
            else 
                  next_state = READ_DATA;
         end
          MASTER_ACK: begin
             if (i2c_tick && !scl_drive_low) begin
                 if (more_data)
                        next_state = READ_DATA;
                else
                         next_state = STOP;
             end else begin
                    next_state = MASTER_ACK;
             end
            end
          STOP: begin
              if (i2c_tick && !scl_drive_low) begin
                  next_state = DONE;
              end else begin
                  next_state = STOP;
              end
           end
           DONE: begin
                    next_state = IDLE;
              end
           ERROR: begin
                     next_state = IDLE;
            end
        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule