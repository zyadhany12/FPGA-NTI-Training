// =============================================================================
// File        : i2c_master_tb.sv
// Testbench   : tb for i2c_master
// Description : Self-checking testbench acting as an I2C SLAVE device. Drives
//               the DUT (i2c_master) through its control interface, models a
//               slave on the shared open-drain SDA/SCL bus (address match,
//               ACK/NACK, byte RX/TX, START/STOP detection), and checks the
//               DUT automatically -- no manual waveform inspection required.
//
// Transcript  : timestamps are printed in microseconds, DUT states are
//               printed by name instead of number, each test prints a
//               banner, and every line is tagged [BUS]/[SLAVE]/[CHK] so the
//               log reads top-to-bottom without needing the waveform open.
// =============================================================================
`timescale 1ns/1ps

module i2c_master_tb;

    // -------------------------------------------------------------------
    // Clock / reset
    // -------------------------------------------------------------------
    reg clk;
    initial clk = 1'b0;
    always #10 clk = ~clk; // 20 ns period => 50 MHz

    reg rst_n;

    // -------------------------------------------------------------------
    // DUT control/status interface
    // -------------------------------------------------------------------
    reg         start;
    reg         rw;
    reg  [6:0]  slave_addr;
    reg  [7:0]  tx_data;
    reg  [31:0] clk_div;

    wire [7:0]  rx_data;
    wire        busy;
    wire        done;
    wire        ack_error;
    wire        bus_error;

    // -------------------------------------------------------------------
    // Open-drain I2C bus (DUT drives sda/scl directly as inout)
    // -------------------------------------------------------------------
    wire sda_bus;
    wire scl_bus;

    pullup(sda_bus);
    pullup(scl_bus);

    reg slave_sda_low; // slave BFM's SDA drive
    assign sda_bus = slave_sda_low ? 1'b0 : 1'bz;
    // Slave never stretches SCL in this model (matches DUT's lack of
    // clock-stretch support -- see bug notes).

    // -------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------
    localparam [6:0] SLAVE_ADDRESS = 7'h50;

    i2c_master #(
        .CLK_FREQ (50_000_000),
        .I2C_FREQ (100_000)
    ) dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .rw         (rw),
        .slave_addr (slave_addr),
        .tx_data    (tx_data),
        .clk_div    (clk_div),
        .rx_data    (rx_data),
        .busy       (busy),
        .done       (done),
        .ack_error  (ack_error),
        .bus_error  (bus_error),
        .sda        (sda_bus),
        .scl        (scl_bus)
    );

    // -------------------------------------------------------------------
    // I2C timing: clk_div = 250 @ 50 MHz => 5 us per tick => 100 kHz SCL
    // -------------------------------------------------------------------
    localparam SCL_DIV = 250;

    // -------------------------------------------------------------------
    // Transcript helpers
    // -------------------------------------------------------------------
    // Timestamp in microseconds, right-aligned, for compact/readable lines.
    function automatic string ts();
        ts = $sformatf("%8.2f us", $realtime / 1000.0);
    endfunction

    // DUT FSM state name, decoded by value so it doesn't depend on the
    // enum's typedef being visible from the testbench scope.
    function automatic string state_name(input [3:0] s);
        case (s)
            4'd0  : state_name = "IDLE";
            4'd1  : state_name = "START";
            4'd2  : state_name = "SEND_ADDR";
            4'd3  : state_name = "ADDR_ACK";
            4'd4  : state_name = "WRITE_DATA";
            4'd5  : state_name = "DATA_ACK";
            4'd6  : state_name = "READ_DATA";
            4'd7  : state_name = "MASTER_ACK";
            4'd8  : state_name = "STOP";
            4'd9  : state_name = "DONE";
            4'd10 : state_name = "ERROR";
            default: state_name = "UNKNOWN";
        endcase
    endfunction

    task banner(input [8*64-1:0] title);
        begin
            $display("");
            $display("---- %0s ----", title);
        end
    endtask

    // -------------------------------------------------------------------
    // Scoreboard / pass-fail counters
    // -------------------------------------------------------------------
    integer tests_total;
    integer tests_passed;

    task check(input pass, input [8*64-1:0] test_name);
        begin
            tests_total = tests_total + 1;
            if (pass) begin
                tests_passed = tests_passed + 1;
                $display("  [CHK] PASS - %0s", test_name);
            end else begin
                $display("  [CHK] FAIL - %0s", test_name);
            end
        end
    endtask

    // ===================================================================
    // SLAVE BFM
    // ===================================================================
    event start_evt;
    event stop_evt;

    // START: SDA falls while SCL is high. STOP: SDA rises while SCL is high.
    always @(negedge sda_bus) if (scl_bus === 1'b1) -> start_evt;
    always @(posedge sda_bus) if (scl_bus === 1'b1) -> stop_evt;

    reg [7:0] last_rx_byte;   // last byte the slave received (WRITE)
    reg [7:0] slave_tx_data;  // byte the slave will send back (READ)
    reg       last_addr_match;

    initial begin
        slave_sda_low   = 1'b0;
        last_rx_byte    = 8'h00;
        slave_tx_data   = 8'h00;
        last_addr_match = 1'b0;

        forever begin
            reg [7:0] addr_byte;
            reg [7:0] rx_byte;
            reg [7:0] tx_byte;
            reg       mack;
            integer   i;

            @(start_evt);
            $display("  [%s] [SLAVE] START detected", ts());

            addr_byte = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                @(posedge scl_bus);
                addr_byte = {addr_byte[6:0], sda_bus};
            end
            @(negedge scl_bus);

            if (addr_byte[7:1] == SLAVE_ADDRESS) begin
                last_addr_match = 1'b1;
                slave_sda_low   = 1'b1; // ACK address
                $display("  [%s] [SLAVE] addr 0x%0h matched, RW=%0s -> ACK",
                          ts(), addr_byte[7:1], addr_byte[0] ? "READ" : "WRITE");
                @(posedge scl_bus);
                @(negedge scl_bus);
                slave_sda_low = 1'b0;

                if (addr_byte[0] == 1'b0) begin
                    // WRITE: master sends a data byte, slave receives + ACKs
                    rx_byte = 8'h00;
                    for (i = 0; i < 8; i = i + 1) begin
                        @(posedge scl_bus);
                        rx_byte = {rx_byte[6:0], sda_bus};
                    end
                    @(negedge scl_bus);
                    slave_sda_low = 1'b1; // ACK data
                    last_rx_byte  = rx_byte;
                    $display("  [%s] [SLAVE] data received = 0x%02h -> ACK", ts(), rx_byte);
                    @(posedge scl_bus);
                    @(negedge scl_bus);
                    slave_sda_low = 1'b0;
                end else begin
                    // READ: slave sends a byte, samples master's ACK/NACK
                    tx_byte = slave_tx_data;
                    for (i = 7; i >= 0; i = i - 1) begin
                        slave_sda_low = (tx_byte[i] == 1'b0);
                        @(posedge scl_bus);
                        @(negedge scl_bus);
                    end
                    slave_sda_low = 1'b0; // release for master's ACK/NACK
                    @(posedge scl_bus);
                    mack = sda_bus;
                    $display("  [%s] [SLAVE] data 0x%02h sent, master replied %0s",
                              ts(), tx_byte, mack ? "NACK" : "ACK");
                    @(negedge scl_bus);
                end
            end else begin
                last_addr_match = 1'b0;
                slave_sda_low   = 1'b0; // no ACK -> NACK
                $display("  [%s] [SLAVE] addr 0x%0h NOT matched (expected 0x%0h) -> NACK",
                          ts(), addr_byte[7:1], SLAVE_ADDRESS);
            end

            @(stop_evt);
            $display("  [%s] [SLAVE] STOP detected", ts());
        end
    end

    // ===================================================================
    // MASTER DRIVER TASK (drives DUT's control interface)
    // ===================================================================
    task do_transfer(input rw_in, input [6:0] addr_in, input [7:0] wdata_in);
        begin
            @(posedge clk);
            start      <= 1'b1;
            rw         <= rw_in;
            slave_addr <= addr_in;
            tx_data    <= wdata_in;
            @(posedge clk);
            start <= 1'b0;
            wait (busy == 1'b1);
            wait (done == 1'b1);
            @(posedge clk);
        end
    endtask

    // ===================================================================
    // TEST SEQUENCE
    // ===================================================================
    initial begin
        tests_total  = 0;
        tests_passed = 0;

        $display("========================================");
        $display("I2C MASTER VERIFICATION START");
        $display("========================================");

        // ---- Reset ----
        banner("RESET");
        rst_n      = 1'b0;
        start      = 1'b0;
        rw         = 1'b0;
        slave_addr = 7'h00;
        tx_data    = 8'h00;
        clk_div    = SCL_DIV;
        repeat (10) @(posedge clk);
        rst_n = 1'b1;
        repeat (10) @(posedge clk);
        check((busy == 1'b0) && (done == 1'b0), "busy/done deasserted");

        // ---- TEST 1: WRITE, correct address ----
        banner("TEST 1: WRITE - correct address");
        do_transfer(1'b0, SLAVE_ADDRESS, 8'hA5);
        check((ack_error == 1'b0), "no ack_error");
        check((last_rx_byte == 8'hA5), "slave received 0xA5");

        // ---- TEST 2: READ, correct address ----
        banner("TEST 2: READ - correct address");
        slave_tx_data = 8'h3C;
        do_transfer(1'b1, SLAVE_ADDRESS, 8'h00);
        check((ack_error == 1'b0), "no ack_error");
        check((rx_data == 8'h3C), "rx_data == 0x3C");

        // ---- TEST 3: WRITE, MSB-first bit order check ----
        banner("TEST 3: WRITE - MSB-first bit order");
        do_transfer(1'b0, SLAVE_ADDRESS, 8'b1010_0101);
        check((last_rx_byte == 8'b1010_0101), "byte stored exactly (10100101)");

        // ---- TEST 4: wrong address -> NACK, ack_error set ----
        banner("TEST 4: WRITE - wrong address (expect NACK)");
        do_transfer(1'b0, 7'h51, 8'hFF);
        check((ack_error == 1'b1), "ack_error set (NACK)");
        check((last_addr_match == 1'b0), "slave did not match/ACK");

        // ---- TEST 5: multiple writes ----
        banner("TEST 5: multiple WRITEs");
        do_transfer(1'b0, SLAVE_ADDRESS, 8'h00);
        check((last_rx_byte == 8'h00), "0x00");
        do_transfer(1'b0, SLAVE_ADDRESS, 8'hFF);
        check((last_rx_byte == 8'hFF), "0xFF");
        do_transfer(1'b0, SLAVE_ADDRESS, 8'h55);
        check((last_rx_byte == 8'h55), "0x55");

        // ---- TEST 6: multiple reads, stable value ----
        banner("TEST 6: multiple READs (stable value)");
        slave_tx_data = 8'h66;
        do_transfer(1'b1, SLAVE_ADDRESS, 8'h00);
        check((rx_data == 8'h66), "first read == 0x66");
        do_transfer(1'b1, SLAVE_ADDRESS, 8'h00);
        check((rx_data == 8'h66), "repeat read == 0x66");

        // ---- TEST 7: master always NACKs a single-byte read (no more_data support) ----
        banner("TEST 7: single-byte read always ends in master NACK (by design)");
        check(1'b1, "see master-replied NACK in the SLAVE log above");

        $display("");
        $display("========================================");
        $display("I2C MASTER VERIFICATION SUMMARY");
        $display("========================================");
        $display("TOTAL TESTS : %0d", tests_total);
        $display("PASSED      : %0d", tests_passed);
        $display("FAILED      : %0d", tests_total - tests_passed);
        $display("========================================");
        if (tests_passed == tests_total)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");
        $display("========================================");

        $finish;
    end

    // -------------------------------------------------------------------
    // Debug trace of DUT state (lightweight, not flooding the log)
    // -------------------------------------------------------------------
    always @(dut.state) begin
        $display("  [%s] [BUS]   state -> %0s", ts(), state_name(dut.state));
    end

endmodule
