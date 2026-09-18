`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// APB I2C Register Block
// -----------------------------------------------------------------------------
// APB4-style register interface for the APB-Controlled I2C project.
//
// Register map:
//   0x00 CTRL
//          [0] START  - write 1 to generate a one-PCLK start pulse
//          [1] RW     - 0 = WRITE, 1 = READ
//
//   0x04 STATUS
//          [0] BUSY
//          [1] DONE
//          [2] ACK_ERROR
//          [3] BUS_ERROR
//          [4] I2C_BUS_BUSY
//
//   0x08 SLAVE_ADDR
//          [6:0] I2C 7-bit slave address
//
//   0x0C TX_DATA
//          [7:0] transmit byte
//
//   0x10 RX_DATA
//          [7:0] receive byte
//
//   0x14 CLK_DIV
//          Clock-divider configuration. Default = 250.
//
//   0x18 INT_STATUS
//          [0] DONE event
//          [1] ACK_ERROR event
//
//   0x1C VERSION
//          Constant 32'h0001_0000
//
// APB behavior:
//   PREADY is always HIGH.
//   Invalid/unimplemented addresses generate PSLVERR=1.
// -----------------------------------------------------------------------------

module apb_i2c_regs #(
    parameter [31:0] CLK_DIV_DEFAULT = 32'd250,
    parameter [31:0] VERSION_VALUE    = 32'h0001_0000
) (
    // APB interface
    input        PCLK,
    input        PRESETn,
    input [11:0] PADDR,
    input        PSEL,
    input        PENABLE,
    input        PWRITE,
    input [31:0] PWDATA,

    output reg [31:0] PRDATA,
    output       PREADY,
    output       PSLVERR,

    // I2C master control
    output reg     master_start,
    output reg     master_rw,
    output reg [6:0] master_slave_addr,
    output reg [7:0] master_tx_data,
    output reg [31:0] master_clk_div,

    // I2C master/status inputs
    input        master_busy,
    input        master_done,
    input        master_ack_error,
    input        master_bus_error,
    input        i2c_bus_busy,
    input [7:0]  master_rx_data
);

    // -------------------------------------------------------------------------
    // Register addresses
    // -------------------------------------------------------------------------
    localparam [11:0] ADDR_CTRL       = 12'h000;
    localparam [11:0] ADDR_STATUS     = 12'h004;
    localparam [11:0] ADDR_SLAVE_ADDR = 12'h008;
    localparam [11:0] ADDR_TX_DATA    = 12'h00C;
    localparam [11:0] ADDR_RX_DATA    = 12'h010;
    localparam [11:0] ADDR_CLK_DIV    = 12'h014;
    localparam [11:0] ADDR_INT_STATUS = 12'h018;
    localparam [11:0] ADDR_VERSION    = 12'h01C;

    // -------------------------------------------------------------------------
    // APB access signals
    // -------------------------------------------------------------------------
    wire apb_access;
    wire apb_write;
    wire apb_read;
    reg  valid_address;

    assign PREADY     = 1'b1;
    assign apb_access = PSEL && PENABLE;
    assign apb_write  = apb_access && PWRITE;
    assign apb_read   = apb_access && !PWRITE;

    always @(*) begin
        case (PADDR)
            ADDR_CTRL,
            ADDR_STATUS,
            ADDR_SLAVE_ADDR,
            ADDR_TX_DATA,
            ADDR_RX_DATA,
            ADDR_CLK_DIV,
            ADDR_INT_STATUS,
            ADDR_VERSION:
                valid_address = 1'b1;

            default:
                valid_address = 1'b0;
        endcase
    end

    assign PSLVERR = apb_access && !valid_address;

    // -------------------------------------------------------------------------
    // Internal status registers
    // -------------------------------------------------------------------------

    reg        done_status;
    reg        ack_error_status;
    reg [7:0]  rx_data_reg;

    // -------------------------------------------------------------------------
    // Register write / status logic
    // -------------------------------------------------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            master_start      <= 1'b0;
            master_rw         <= 1'b0;
            master_slave_addr <= 7'h00;
            master_tx_data    <= 8'h00;
            master_clk_div    <= CLK_DIV_DEFAULT;

            done_status       <= 1'b0;
            ack_error_status  <= 1'b0;
            rx_data_reg       <= 8'h00;
        end
        else begin
            // START is a command and therefore only lasts one PCLK cycle.
            master_start <= 1'b0;

            // Capture I2C completion information.
            if (master_done) begin
                done_status      <= 1'b1;
                ack_error_status <= master_ack_error;
                rx_data_reg      <= master_rx_data;
            end

            // APB writes occur during the ACCESS phase.
            if (apb_write && valid_address) begin
                case (PADDR)

                    ADDR_CTRL: begin
                        // RW is a persistent configuration bit.
                        master_rw <= PWDATA[1];

                        // START is a one-cycle command.
                        // Do not start a transaction while master is busy.
                        if (PWDATA[0] && !master_busy) begin
                            master_start      <= 1'b1;
                            done_status       <= 1'b0;
                            ack_error_status  <= 1'b0;
                        end
                    end

                    ADDR_SLAVE_ADDR: begin
                        master_slave_addr <= PWDATA[6:0];
                    end

                    ADDR_TX_DATA: begin
                        master_tx_data <= PWDATA[7:0];
                    end

                    ADDR_CLK_DIV: begin
                        // Zero is not a useful divider value.
                        if (PWDATA != 32'd0)
                            master_clk_div <= PWDATA;
                    end

                    // Read-only/status registers.
                    ADDR_STATUS,
                    ADDR_RX_DATA,
                    ADDR_INT_STATUS,
                    ADDR_VERSION: begin
                        // No action.
                    end

                    default: begin
                        // Invalid addresses are handled by PSLVERR.
                    end
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // APB read mux
    // -------------------------------------------------------------------------
    always @(*) begin
        PRDATA = 32'h0000_0000;

        if (apb_read) begin
            case (PADDR)

                ADDR_CTRL: begin
                    PRDATA = {30'h0, master_rw, 1'b0};
                end

                ADDR_STATUS: begin
                    PRDATA = {
                        27'h0,
                        i2c_bus_busy,
                        master_bus_error,
                        ack_error_status,
                        done_status,
                        master_busy
                    };
                end

                ADDR_SLAVE_ADDR: begin
                    PRDATA = {25'h0, master_slave_addr};
                end

                ADDR_TX_DATA: begin
                    PRDATA = {24'h0, master_tx_data};
                end

                ADDR_RX_DATA: begin
                    PRDATA = {24'h0, rx_data_reg};
                end

                ADDR_CLK_DIV: begin
                    PRDATA = master_clk_div;
                end

                ADDR_INT_STATUS: begin
                    PRDATA = {
                        30'h0,
                        ack_error_status,
                        done_status
                    };
                end

                ADDR_VERSION: begin
                    PRDATA = VERSION_VALUE;
                end

                default: begin
                    PRDATA = 32'h0000_0000;
                end
            endcase
                end
    end

endmodule
