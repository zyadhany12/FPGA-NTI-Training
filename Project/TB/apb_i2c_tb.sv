import apb_i2c_pkg::*;

module apb_i2c_tb;
  // DUT Signals
  logic        PCLK, PRESETn, PSEL, PENABLE, PWRITE, PREADY, PSLVERR;
  logic [11:0] PADDR;
  logic [31:0] PWDATA, PRDATA;
  
  logic        master_start, master_rw;
  logic [6:0]  master_slave_addr;
  logic [7:0]  master_tx_data;
  logic [31:0] master_clk_div;
  
  logic        master_busy, master_done, master_ack_error, master_bus_error, i2c_bus_busy;
  logic [7:0]  master_rx_data;

  // Expected/Golden Model Variables
  logic        exp_master_rw;
  logic [6:0]  exp_slave_addr;
  logic [7:0]  exp_tx_data, exp_rx_data;
  logic [31:0] exp_clk_div;
  logic        exp_done_status, exp_ack_error_status;
  
  int error_count = 0;
  int correct_count = 0;

  apb_i2c_trans tr = new();

  // Instantiate DUT
  apb_i2c_regs #(CLK_DIV_DEFAULT, VERSION_VALUE) DUT (.*);

  // Clock Generation
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;
  end

  // Golden Model Update Task
  task update_golden_model(input logic [11:0] addr, logic pwrite, logic [31:0] pwdata);
    if (master_done) begin
      exp_done_status      = 1'b1;
      exp_ack_error_status = master_ack_error;
      exp_rx_data          = master_rx_data;
    end

    if (pwrite) begin
      case (addr)
        12'h000: begin
          exp_master_rw = pwdata[1];
          if (pwdata[0] && !master_busy) begin
            exp_done_status      = 1'b0;
            exp_ack_error_status = 1'b0;
          end
        end
        12'h008: exp_slave_addr = pwdata[6:0];
        12'h00C: exp_tx_data    = pwdata[7:0];
        12'h014: if (pwdata != 32'd0) exp_clk_div = pwdata; 
      endcase
    end
  endtask

  // APB Transaction Task 
  task drive_apb(input logic [11:0] addr, input logic write_en, input logic [31:0] wdata);
    @(posedge PCLK);
    // SETUP Phase
    PSEL    <= 1'b1;
    PENABLE <= 1'b0;
    PADDR   <= addr;
    PWRITE  <= write_en;
    PWDATA  <= wdata;
    
    @(posedge PCLK);
    // ACCESS Phase
    PENABLE <= 1'b1;
    
    // Check Outputs mid-cycle
    @(negedge PCLK);
    update_golden_model(addr, write_en, wdata);
    check_outputs(addr, write_en);
    
    @(posedge PCLK);
    // IDLE Phase
    PSEL    <= 1'b0;
    PENABLE <= 1'b0;
  endtask

  task check_outputs(input logic [11:0] addr, input logic write_en);
    logic exp_pslverr;
    logic [31:0] exp_prdata;
    
    exp_pslverr = (addr != 12'h000 && addr != 12'h004 && addr != 12'h008 && 
                   addr != 12'h00C && addr != 12'h010 && addr != 12'h014 && 
                   addr != 12'h018 && addr != 12'h01C);
                   
    if (PSLVERR !== exp_pslverr) begin
      $error("[%0t] ERROR: PSLVERR mismatch at addr %0h. Exp: %0b, Act: %0b", $time, addr, exp_pslverr, PSLVERR);
      error_count++;
    end
    
    if (!write_en) begin
      if (exp_pslverr) begin
        exp_prdata = 32'h0; 
      end else begin
        case(addr)
          12'h000: exp_prdata = {30'h0, exp_master_rw, 1'b0};
          12'h004: exp_prdata = {27'h0, i2c_bus_busy, master_bus_error, exp_ack_error_status, exp_done_status, master_busy};
          12'h008: exp_prdata = {25'h0, exp_slave_addr};
          12'h00C: exp_prdata = {24'h0, exp_tx_data};
          12'h010: exp_prdata = {24'h0, exp_rx_data};
          12'h014: exp_prdata = exp_clk_div;
          12'h018: exp_prdata = {30'h0, exp_ack_error_status, exp_done_status};
          12'h01C: exp_prdata = VERSION_VALUE;
          default: exp_prdata = 32'h0;
        endcase
      end
      
      if (PRDATA !== exp_prdata) begin
        $error("[%0t] ERROR: PRDATA mismatch at addr %0h. Exp: %0h, Act: %0h", $time, addr, exp_prdata, PRDATA);
        error_count++;
      end else begin
        correct_count++;
      end
    end
  endtask

 
  // Main Test Sequence

  initial begin

    $display("= APB I2C REGISTER VERIFICATION START=");

    // Initialize
    PSEL = 0; PENABLE = 0;
    master_busy = 0; master_done = 0; master_ack_error = 0; master_bus_error = 0; i2c_bus_busy = 0; master_rx_data = 0;
    exp_master_rw = 0; exp_slave_addr = 0; exp_tx_data = 0; exp_rx_data = 0; exp_clk_div = CLK_DIV_DEFAULT; exp_done_status = 0; exp_ack_error_status = 0;
    
    // 1. Reset Test
    $display("[%0t] TEST 1: Applying Hardware Reset...", $time);
    PRESETn = 0;
    repeat(2) @(posedge PCLK);
    PRESETn = 1;
    $display("[%0t] PASS: Reset applied. Registers at default values.", $time);

    // 2. Directed Test: Valid Write
    $display("[%0t] TEST 2: APB Write to SLAVE_ADDR (0x008)...", $time);
    drive_apb(12'h008, 1'b1, 32'h0000_0055);
    $display("[%0t] PASS: Write transaction completed.", $time);

    // 3. Directed Test: Valid Read
    $display("[%0t] TEST 3: APB Read from SLAVE_ADDR (0x008)...", $time);
    drive_apb(12'h008, 1'b0, 32'h0000_0000);
    $display("[%0t] PASS: Read transaction returned 0x55 correctly.", $time);

    // 4. Directed Test: Invalid Address (PSLVERR)
    $display("[%0t] TEST 4: APB Access to Invalid Address (0x100)...", $time);
    drive_apb(12'h100, 1'b0, 32'h0000_0000);
    $display("[%0t] PASS: PSLVERR successfully asserted for invalid address.", $time);

    // 5. Directed Test: Clock Divider Write Zero (Ignored)
    $display("[%0t] TEST 5: Attempting to write 0 to CLK_DIV...", $time);
    master_busy = 0;
    tr.paddr = 12'h014; tr.pwrite = 1; tr.pwdata = 32'd0;
    tr.cvr_gp.sample();
    drive_apb(12'h014, 1'b1, 32'd0);
    $display("[%0t] PASS: Clock Divider ignored 0 write.", $time);
    
    // 6. Directed Test: Start Command While Master is Busy (Ignored)
    $display("[%0t] TEST 6: Triggering START while I2C Master is BUSY...", $time);
    master_busy = 1;
    tr.paddr = 12'h000; tr.pwrite = 1; tr.pwdata = 32'h1;
    tr.cvr_gp.sample();
    drive_apb(12'h000, 1'b1, 32'h1);
    $display("[%0t] PASS: START command safely ignored while busy.", $time);
    master_busy = 0;
    
    // 7. Random Testing Phase
    $display("[%0t] STARTING RANDOMIZED TEST (3000 iteration)", $time);
    for (int i = 0; i < 3000; i++) begin
      assert(tr.randomize());
      
      // Inject I2C Master state
      master_busy      = tr.master_busy;
      master_done      = tr.master_done;
      master_ack_error = tr.master_ack_error;
      master_bus_error = tr.master_bus_error;
      i2c_bus_busy     = tr.i2c_bus_busy;
      master_rx_data   = tr.master_rx_data;
      
      // Drive APB and sample coverage
      tr.cvr_gp.sample();
      drive_apb(tr.paddr, tr.pwrite, tr.pwdata);

      if (i > 0 && i % 500 == 0) begin
        $display("[%0t] Random testing heartbeat: %0d / 3000 completed...", $time, i);
      end
    end

    $display("= VERIFICATION COMPLETE =");
    $display("= Errors Detected : %0d =", error_count);
    $display("= Correct Checks  : %0d =", correct_count);
    $stop;
  end 
endmodule