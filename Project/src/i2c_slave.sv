// =============================================================================
// File        : i2c_slave.sv
// Module      : i2c_slave
// Project     : APB-Controlled I2C Master with I2C Slave
// Owner       : PERSON 2 (Yousef Hatem abdeljalil)
// Description : Synthesizable I2C Slave (Standard-mode, 7-bit addressing,
//               8-bit data, single byte per transaction). Synchronous to the
//               system clock `clk`. Does NOT generate its own I2C clock and
//               does NOT implement APB. Observes scl_in/sda_in and drives
//               the shared open-drain SDA line only through sda_drive_low.
// =============================================================================

module i2c_slave #(
    parameter [6:0] SLAVE_ADDRESS = 7'h50 // Default slave address (7-bit)
) (
    input  wire       clk,            // system clock (50 MHz per spec)
    input  wire       rst,            // synchronous-style active-high reset, sampled on clk
    input  wire       scl_in,         // I2C SCL bus level (input only)
    input  wire       sda_in,         // I2C SDA bus level (input only)
    output wire       sda_drive_low,  // 1 = pull SDA low, 0 = release SDA
    output wire [7:0] rx_data         // internal data register 
);

    // -------------------------------------------------------------------
    // FSM state encoding
    // -------------------------------------------------------------------
    typedef enum reg [2:0] {
        IDLE,           // Bus idle; wait for a START condition.
        RECV_ADDR,      // Receive 8 bits (7-bit address + R/W) MSB-first.
        ADDR_ACK,       // Drive/withhold ACK for the address byte; decide WRITE vs READ vs ignore.
        WRITE_DATA,     // Receive 8 data bits MSB-first from the master.
        DATA_ACK,       // Drive ACK for the received data byte.
        READ_DATA,      // Transmit 8 data bits MSB-first to the master.
        READ_ACK,       // Release SDA; capture (but do not act on) the master's ACK/NACK.
        WAIT_STOP       // Release SDA; wait for STOP to return to IDLE.
    } state_t;

    state_t state;

    // -------------------------------------------------------------------
    // Bus synchronizers (2-FF) + previous-value registers for edge detection
    // -------------------------------------------------------------------
    reg scl_meta, scl_sync, scl_sync_d;
    reg sda_meta, sda_sync, sda_sync_d;
    
    // -------------------------------------------------------------------
    // Datapath registers
    // -------------------------------------------------------------------
    reg [7:0] rx_shift_reg;       // receive shift register (address or write data)
    reg [7:0] tx_shift_reg;       // transmit shift register (read data)
    reg [7:0] data_reg;           // internal data register (rx_data source / read source)
    reg [2:0] bit_count;          // 0..7 bit index within the current byte
    reg       rw_bit;             // latched R/W bit from the address byte
    reg       address_match;      // latched result of address comparison
    reg       sda_drive_low_reg;  // registered version of sda_drive_low output
    reg       addr_byte_done;     // indicates that the address byte has been fully received
    reg       data_byte_done;     // indicates that the data byte has been fully received or transmitted
    reg       ack_seen;           // indicates that an ACK/NACK bit's sampling (rising) edge has already occurred.
    reg       master_ack_nack;    // debug/verification only: captured value of the master's ACK/NACK bit during READ_ACK (0 = ACK, 1 = NACK). 
    
    reg       scl_rising;         // indicates that a rising edge of SCL has been detected
    reg       scl_falling;        // indicates that a falling edge of SCL has been detected
    reg       start_cond;         // indicates that a start condition has been detected
    reg       stop_cond;          // indicates that a stop condition has been detected
    
    always @(*) begin
        // Edge detection for SCL and SDA
        scl_rising  = (scl_sync) && (!scl_sync_d);
        scl_falling = (!scl_sync) && (scl_sync_d);
        
        // Start condition: SDA goes low while SCL is high
        start_cond  = (!sda_sync) && (sda_sync_d) && (scl_sync) && (scl_sync_d);
        
        // Stop condition: SDA goes high while SCL is high
        stop_cond   = (sda_sync) && (!sda_sync_d) && (scl_sync) && (scl_sync_d);
    end


    always @(posedge clk) begin
        if (rst) begin
            // Initialize synchronizers to the I2C bus idle state (SDA = SCL = HIGH).
            sda_meta   <= 1'b1;
            sda_sync   <= 1'b1;
            sda_sync_d <= 1'b1;

            scl_meta   <= 1'b1;
            scl_sync   <= 1'b1;
            scl_sync_d <= 1'b1;        
        end 
        else begin
            sda_meta   <= sda_in;
            sda_sync   <= sda_meta;
            sda_sync_d <= sda_sync;

            scl_meta   <= scl_in;
            scl_sync   <= scl_meta;
            scl_sync_d <= scl_sync;        
        end
    end
    
    always @(posedge clk) begin
        if (rst) begin
            state               <= IDLE;
            rx_shift_reg        <= 8'd0;
            tx_shift_reg        <= 8'd0;
            data_reg            <= 8'd0;
            bit_count           <= 3'd0;
            rw_bit              <= 1'd0;
            address_match       <= 1'b0;
            sda_drive_low_reg   <= 1'b0;
            addr_byte_done      <= 1'b0;
            data_byte_done      <= 1'b0;
            ack_seen            <= 1'b0;
            master_ack_nack     <= 1'b0;
        end

        else if (start_cond) begin
            state               <= RECV_ADDR;
            bit_count           <= 3'd0;
            rx_shift_reg        <= 8'd0;
            sda_drive_low_reg   <= 1'b0;
            addr_byte_done      <= 1'b0;
            data_byte_done      <= 1'b0;
            ack_seen            <= 1'b0;
        end

        else if (stop_cond) begin
            // STOP detected: always return to IDLE and release the bus,
            state               <= IDLE;
            sda_drive_low_reg   <= 1'b0;
            addr_byte_done      <= 1'b0;
            data_byte_done      <= 1'b0;
            ack_seen            <= 1'b0; 
        end

        else begin
            case (state)
                
                IDLE:       begin 
                    sda_drive_low_reg <= 1'b0;
                end

                RECV_ADDR:  begin
                    if(scl_rising) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_sync};

                        if (bit_count == 3'd7) begin
                            bit_count      <= 3'd0;
                            addr_byte_done <= 1'b1; 
                        end
                        else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end

                    else if (scl_falling && addr_byte_done) begin
                        // Full address+R/W byte received; safe to evaluate
                        // and change SDA now because SCL just went low.
                        addr_byte_done      <= 1'b0;
                        rw_bit              <= rx_shift_reg[0];
                        address_match       <= (rx_shift_reg[7:1] == SLAVE_ADDRESS[6:0]);
                        // Drive ACK only if the address matches; otherwise
                        // stay released for the whole ACK cell.
                        sda_drive_low_reg   <= (rx_shift_reg[7:1] == SLAVE_ADDRESS[6:0]);
                        ack_seen            <= 1'b0;
                        state               <= ADDR_ACK;
                    end
                end

                ADDR_ACK:   begin
                    if (!ack_seen) begin
                        if (scl_rising) begin
                            ack_seen <= 1'b1; // master is sampling ACK/NACK now
                        end
                    end
                    else begin
                        if (scl_falling) begin
                            ack_seen <= 1'b0;
                            if (address_match) begin
                                if (rw_bit) begin
                                    // READ transaction: preload transmit
                                    // shift register from the internal data
                                    // register and drive the first (MSB) bit.
                                    tx_shift_reg      <= data_reg;
                                    bit_count         <= 3'd0;
                                    sda_drive_low_reg <= ~data_reg[7];
                                    state             <= READ_DATA;
                                end
                                else begin
                                    // WRITE transaction: release SDA, master
                                    // will drive the data byte.
                                    bit_count         <= 3'd0;
                                    sda_drive_low_reg <= 1'b0;
                                    state             <= WRITE_DATA;
                                end
                            end
                            else begin
                                // Address mismatch: never ACKed, ignore the
                                // rest of the transaction until STOP.
                                sda_drive_low_reg     <= 1'b0;
                                state                 <= WAIT_STOP;
                            end
                        end
                    end
                end

                WRITE_DATA: begin
                    if (scl_rising) begin
                        rx_shift_reg <= {rx_shift_reg[6:0], sda_sync};

                        if (bit_count == 3'd7) begin
                            bit_count      <= 3'd0;
                            data_byte_done <= 1'b1;
                        end
                        else begin
                            bit_count <= bit_count + 3'd1;
                        end
                    end
                    else if (scl_falling && data_byte_done) begin
                        data_byte_done    <= 1'b0;
                        data_reg          <= rx_shift_reg; // commit received byte
                        sda_drive_low_reg <= 1'b1;         // drive ACK
                        ack_seen          <= 1'b0;
                        state             <= DATA_ACK;
                    end
                end

                DATA_ACK:   begin
                    if (!ack_seen) begin
                        if (scl_rising) begin
                            ack_seen <= 1'b1; // master samples our ACK now
                        end
                    end
                    else begin
                        if (scl_falling) begin
                            ack_seen          <= 1'b0;
                            sda_drive_low_reg <= 1'b0;
                            state             <= WAIT_STOP; // single-byte transaction
                        end  
                    end
                end
                
                READ_DATA:  begin
                    if(scl_rising) begin
                        // Master samples the current bit now; SDA must not
                        // change until SCL falls again. Nothing to do here
                        // except recognize the last-bit boundary.
                    end
                    else if (scl_falling) begin
                        if (bit_count == 3'd7) begin
                            // All 8 bits have been transmitted and sampled;
                            // release SDA for the master's ACK/NACK.
                            bit_count         <= 3'd0;
                            sda_drive_low_reg <= 1'b0;
                            ack_seen          <= 1'b0;
                            state             <= READ_ACK;
                        end
                        else begin
                            bit_count         <= bit_count + 3'd1;
                            tx_shift_reg      <= {tx_shift_reg[6:0], 1'b0};
                            sda_drive_low_reg <= ~tx_shift_reg[6];
                        end
                    end
                end
                
                READ_ACK:   begin
                    if (!ack_seen) begin
                        if (scl_rising) begin
                            // Sample the master's ACK/NACK bit.
                            master_ack_nack <= sda_sync;
                            ack_seen        <= 1'b1;
                        end
                    end 
                    else begin
                        if (scl_falling) begin
                            ack_seen <= 1'b0;
                            state    <= WAIT_STOP;
                        end
                    end
                end
                
                WAIT_STOP: begin
                    sda_drive_low_reg <= 1'b0;
                    // Returns to IDLE via the global stop_cond handling above.
                end

                default: begin
                    state             <= IDLE;
                    sda_drive_low_reg <= 1'b0;
                end
            endcase
        end
    end

    // -------------------------------------------------------------------
    // Outputs
    // -------------------------------------------------------------------
    assign sda_drive_low = sda_drive_low_reg;
    assign rx_data       = data_reg;

endmodule