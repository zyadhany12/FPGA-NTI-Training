package apb_i2c_pkg;

  parameter [31:0] CLK_DIV_DEFAULT = 32'd250;
  parameter [31:0] VERSION_VALUE   = 32'h0001_0000;

  class apb_i2c_trans;
    // APB stimulus
    rand bit [11:0] paddr;
    rand bit        pwrite;
    rand bit [31:0] pwdata;
    
    // I2C Master Status stimulus (simulating the external I2C master)
    rand bit        master_busy;
    rand bit        master_done;
    rand bit        master_ack_error;
    rand bit        master_bus_error;
    rand bit        i2c_bus_busy;
    rand bit [7:0]  master_rx_data;

    
    constraint addr_c {
      paddr dist {
        12'h000 := 10, 12'h004 := 10, 12'h008 := 10, 12'h00C := 10,
        12'h010 := 10, 12'h014 := 10, 12'h018 := 10, 12'h01C := 10,
        [12'h020:12'hFFF] :/ 20 
      };
    }

    // Functional Coverage
    covergroup cvr_gp;
      // Cover all valid registers being read and written
      cp_addr: coverpoint paddr {
        bins ctrl       = {12'h000};
        bins status     = {12'h004};
        bins slave_addr = {12'h008};
        bins tx_data    = {12'h00C};
        bins rx_data    = {12'h010};
        bins clk_div    = {12'h014};
        bins int_status = {12'h018};
        bins version    = {12'h01C};
        bins invalid    = {[12'h020:12'hFFF]};
      }
      cp_rw: coverpoint pwrite;  // pwrite equal 1 and zero so when we make cross coverage all comb with paddr is made
      
      // Cross coverage to ensure we read and write every register 
      cx_addr_rw: cross cp_addr, cp_rw;
      
      // Cover the I2C status inputs
      cp_done: coverpoint master_done;
      cp_ack_err: coverpoint master_ack_error;
      cp_bus_err: coverpoint master_bus_error;

      // Track if we attempted to write 0 to the clock divider
      cp_clk_div_zero: coverpoint pwdata {
        bins zero_write = {32'd0} iff (paddr == 12'h014 && pwrite == 1);
      }

      // Track if we attempted to trigger START while the master was busy
      cp_start_while_busy: coverpoint pwdata[0] {
        bins busy_start = {1'b1} iff (paddr == 12'h000 && pwrite == 1 && master_busy == 1);
        bins idle_start = {1'b1} iff (paddr == 12'h000 && pwrite == 1 && master_busy == 0);
      }
    endgroup

    function new();
      cvr_gp = new();
    endfunction
  endclass

endpackage : apb_i2c_pkg