`timescale 1ns/1ps
module Top_Module_tb;
    // Testbench signals
    reg PCLK;
    reg PRESETn;
    reg [11:0] PADDR;
    reg PSEL;
    reg PENABLE;
    reg PWRITE;
    reg [31:0] PWDATA;
    wire [31:0] PRDATA;
    wire PREADY;
    wire PSLVERR;
    wire SDA;
    wire SCL;

    
    pullup(SDA);
    pullup(SCL);

    // Instantiate the Top_Module
    Top_Module uut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PADDR(PADDR),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .SDA(SDA),
        .SCL(SCL)
    );
    localparam [11:0] ADDR_CTRL       = 12'h000;
    localparam [11:0] ADDR_STATUS     = 12'h004;
    localparam [11:0] ADDR_SLAVE_ADDR = 12'h008;
    localparam [11:0] ADDR_TX_DATA    = 12'h00C;
    localparam [11:0] ADDR_RX_DATA    = 12'h010;
    localparam [11:0] ADDR_CLK_DIV    = 12'h014;
    localparam [11:0] ADDR_INT_STATUS = 12'h018;
    localparam [11:0] ADDR_VERSION    = 12'h01C;
    localparam [11:0] ADDR_INVALID    = 12'h020;
 
    localparam [31:0] EXPECTED_VERSION   = 32'h0001_0000;
    localparam [6:0]  SLAVE_ADDR_MATCH   = 7'h50;   
    localparam [6:0]  SLAVE_ADDR_WRONG   = 7'h55;   



    initial PCLK = 0;
    always #10 PCLK = ~PCLK; // 50 MHz clock


    // Testbench variables
    integer test_num   = 0;
    integer pass_count = 0;
    integer fail_count = 0;



    // Task to check test results
    task check(input pass, input [8*64-1:0] test_name);
        begin
            test_num = test_num + 1;
            if (pass) begin
                pass_count = pass_count + 1;
                $display("PASS: %0s", test_name);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: %0s", test_name);
            end
        end
    endtask


    //-------------------------------------------------------------------------
    // APB BFM (Bus Functional Model) tasks
    //-------------------------------------------------------------------------
    task automatic apb_write(input [11:0] addr, input [31:0] wdata);
        begin
            @(posedge PCLK);
            PADDR   <= addr;
            PWDATA  <= wdata;
            PWRITE  <= 1'b1;
            PSEL    <= 1'b1;
            PENABLE <= 1'b0;
            @(posedge PCLK);
            PENABLE <= 1'b1;
            @(posedge PCLK);          // PREADY sampled here (tied high in DUT)
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            PWRITE  <= 1'b0;
        end
    endtask

     task automatic apb_read(input [11:0] addr, output [31:0] rdata);
        begin
            @(posedge PCLK);
            PADDR   <= addr;
            PWRITE  <= 1'b0;
            PSEL    <= 1'b1;
            PENABLE <= 1'b0;
            @(posedge PCLK);
            PENABLE <= 1'b1;
            @(posedge PCLK);          // access phase completes here
            #1;
            rdata = PRDATA;
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
        end
    endtask


    // Task to perform an APB write and check for PSLVERR
    // This task writes to invalid address and checks if PSLVERR is asserted
    task automatic apb_write_expect_err(input [11:0] addr, input [31:0] wdata, output err);
        begin
            @(posedge PCLK);
            PADDR   <= addr;
            PWDATA  <= wdata;
            PWRITE  <= 1'b1;
            PSEL    <= 1'b1;
            PENABLE <= 1'b0;
            @(posedge PCLK);
            PENABLE <= 1'b1;
            @(posedge PCLK);
            #1;
            err = PSLVERR;
            PSEL    <= 1'b0;
            PENABLE <= 1'b0;
            PWRITE  <= 1'b0;
        end
    endtask



    // Task to wait for the I2C transaction to complete and check for errors
    // This task polls the STATUS register until the DONE bit is set or a timeout occurs
    task automatic apb_wait_done(output ack_err, output bus_err);
        reg [31:0] status;
        integer    timeout;
        begin
            timeout = 0;
            status  = 32'h0;
            while (!status[1] && timeout < 5000) begin  
                apb_read(ADDR_STATUS, status);
                timeout = timeout + 1;
            end
            if (timeout >= 5000) begin
                $display("ERROR: timeout waiting for DONE (STATUS never asserted DONE)");
                $fatal(1, "Timeout waiting for I2C transaction to complete");
            end
            ack_err = status[2];
            bus_err = status[3];
        end
    endtask



    //-------------------------------------------------------------------------
    // I2C BFM (Bus Functional Model) tasks
    //-------------------------------------------------------------------------
    // Task to perform an I2C write operation using the APB interface


    task automatic i2c_write(input [6:0] addr, input [7:0] data, output ack_err);
        reg bus_err;
        begin
            apb_write(ADDR_SLAVE_ADDR, {25'h0, addr});
            apb_write(ADDR_TX_DATA,    {24'h0, data});
            apb_write(ADDR_CTRL,       {30'h0, 1'b0, 1'b1});  // RW=0 (WRITE), START=1
            apb_wait_done(ack_err, bus_err);
        end
    endtask
 

    // Task to perform an I2C read operation using the APB interface
    task automatic i2c_read(input [6:0] addr, output [7:0] data, output ack_err);
        reg bus_err;
        reg [31:0] rdata;
        begin
            apb_write(ADDR_SLAVE_ADDR, {25'h0, addr});
            apb_write(ADDR_CTRL,       {30'h0, 1'b1, 1'b1});  // RW=1 (READ), START=1
            apb_wait_done(ack_err, bus_err);
            apb_read(ADDR_RX_DATA, rdata);
            data = rdata[7:0];
        end
    endtask


    //-------------------------------------------------------------------------
    // Testbench main process
    //-------------------------------------------------------------------------

    reg [31:0] rdata32; // variable to hold read data from APB reads
    reg [7:0]  rx_byte; // variable to hold received byte from I2C read
    reg        ack_err; // variable to hold ACK error status from I2C operations
    integer    i;       // loop variable for iterations

    reg [7:0] seq_data [0:3];  // array to hold a sequence of data bytes for testing

     initial 
     begin

        $display("==========================================");
        $display("APB-I2C VERIFICATION START");
        $display("==========================================");


        // Default Data for Sequence Test
        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = 12'h0;
        PWDATA  = 32'h0;

        //-----------------------------------------
        // Reset the DUT
        //-----------------------------------------
        PRESETn = 1'b0;
        repeat(5) @(posedge PCLK);
        PRESETn = 1'b1;
        repeat(5) @(posedge PCLK);

    
        apb_read(ADDR_STATUS, rdata32); 
        check(rdata32[4:0] == 5'b0, "RESET: STATUS busy/done/ack_error/bus_error/bus_busy all clear"); 
 
        apb_read(ADDR_VERSION, rdata32);
        check(rdata32 == EXPECTED_VERSION, "RESET: VERSION register reads expected constant");
 
        check((SDA === 1'b1) && (SCL === 1'b1), "RESET: SDA and SCL released (bus idle high)");



        // -----------------------------------------------------------
        // TEST 2: SINGLE WRITE (addr=0x50, data=0xA5)
        // -----------------------------------------------------------

        i2c_write(SLAVE_ADDR_MATCH, 8'hA5, ack_err);
        check(ack_err == 1'b0, "WRITE 0xA5: no ACK error reported");
        check(uut.i2c_slave.rx_data == 8'hA5, "WRITE 0xA5: slave received correct data byte");


        // -----------------------------------------------------------
        // TEST 3: SINGLE READ (readback the byte just written)
        // -----------------------------------------------------------

        i2c_read(SLAVE_ADDR_MATCH, rx_byte, ack_err);
        check(ack_err == 1'b0, "READ 0xA5: no ACK error reported");
        check(rx_byte == 8'hA5, "READ 0xA5: master RX_DATA matches expected byte");


        // -----------------------------------------------------------
        // TEST 4: MULTIPLE WRITES
        // -----------------------------------------------------------
        seq_data[0] = 8'h00;
        seq_data[1] = 8'hFF;
        seq_data[2] = 8'h55;
        seq_data[3] = 8'hAA;
 
        for (i = 0; i < 4; i = i + 1) begin
            i2c_write(SLAVE_ADDR_MATCH, seq_data[i], ack_err);
            check(ack_err == 1'b0, "MULTIPLE WRITE: no ACK error");
            check(uut.i2c_slave.rx_data == seq_data[i], "MULTIPLE WRITE: slave data matches written value");
        end

        // -----------------------------------------------------------
        // TEST 5: MULTIPLE READS (re-read the values just written above)
        // -----------------------------------------------------------

        for (i = 0; i < 4; i = i + 1) begin
            i2c_read(SLAVE_ADDR_MATCH, rx_byte, ack_err);
            check(ack_err == 1'b0, "MULTIPLE READ: no ACK error");

            // Slave always returns whatever was last written to it, so
            // every read in this loop should return seq_data[3]. as its
            // only 8 bit register and it will hold the last value written to it.

            check(rx_byte == seq_data[3], "MULTIPLE READ: master RX_DATA matches expected byte");
        end


        // -----------------------------------------------------------
        // TEST 6: Invalid ADDRESS
        // -----------------------------------------------------------

        i2c_write(SLAVE_ADDR_WRONG, 8'h5A, ack_err); 
        check(ack_err == 1'b1, "Invalid ADDRESS: ACK_ERROR asserted (slave did not ACK)");
 
        apb_read(ADDR_STATUS, rdata32);
        check(rdata32[0] == 1'b0, "Invalid ADDRESS: bus returns to idle (BUSY=0)");



        // -----------------------------------------------------------
        // TEST 7: RANDOM TRANSACTIONS
        // -----------------------------------------------------------

        begin : random_test
            reg [7:0] rand_data;
            reg       rand_ok;
            rand_ok = 1'b1;
            for (i = 0; i < 10; i = i + 1) begin
                rand_data = $random;
                i2c_write(SLAVE_ADDR_MATCH, rand_data, ack_err);
                if (ack_err !== 1'b0 || uut.i2c_slave.rx_data !== rand_data)
                    rand_ok = 1'b0;
 
                i2c_read(SLAVE_ADDR_MATCH, rx_byte, ack_err);
                if (ack_err !== 1'b0 || rx_byte !== rand_data)
                    rand_ok = 1'b0;
            end
            check(rand_ok, "RANDOM: 10 write/read pairs all matched");
        end



        // -----------------------------------------------------------
        // TEST 8: INVALID APB ADDRESS PSLVERR CHECK
        // -----------------------------------------------------------
        begin : pslverr_test
            reg err;
            apb_write_expect_err(ADDR_INVALID, 32'hDEAD_BEEF, err);
            check(err == 1'b1, "INVALID ADDRESS: PSLVERR asserted");
        end


        // -----------------------------------------------------------
        // Summary
        // -----------------------------------------------------------
        $display("==========================================");
        $display("TOTAL TESTS : %0d", test_num);
        $display("PASSED      : %0d", pass_count);
        $display("FAILED      : %0d", fail_count);
        $display("==========================================");
 
        if (fail_count != 0)
            $fatal(1, "One or more tests FAILED");
 
        $finish;
    end

endmodule


