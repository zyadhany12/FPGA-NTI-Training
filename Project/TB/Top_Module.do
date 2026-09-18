# =============================================================================
# File   : wave.do
# Usage  : At the ModelSim/Questa "VSIM>" prompt (or via -do), after loading
#          work.Top_Module_tb, run:
#              do wave.do
#              run -all
#          Or from the shell, compile+load first, then run this script:
#              vsim work.Top_Module_tb -do "do wave.do; run -all"
#
# Purpose: Adds the reduced signal set called for in the spec (section 21) --
#          just enough to read APB transactions and I2C bus activity, not the
#          full internal signal list of every module.
# =============================================================================

# Start clean
delete wave *

# -------------------------------------------------------------------------
# APB interface
# -------------------------------------------------------------------------
add wave -divider "APB"
add wave -color yellow                 sim:/Top_Module_tb/PCLK
add wave                               sim:/Top_Module_tb/PSEL
add wave                               sim:/Top_Module_tb/PENABLE
add wave                               sim:/Top_Module_tb/PWRITE
add wave -radix hexadecimal            sim:/Top_Module_tb/PADDR
add wave -radix hexadecimal            sim:/Top_Module_tb/PWDATA
add wave -radix hexadecimal            sim:/Top_Module_tb/PRDATA
add wave                               sim:/Top_Module_tb/PREADY
add wave                               sim:/Top_Module_tb/PSLVERR

# -------------------------------------------------------------------------
# I2C bus (physical pins)
# -------------------------------------------------------------------------
add wave -divider "I2C Bus"
add wave -color cyan                   sim:/Top_Module_tb/SCL
add wave -color orange                 sim:/Top_Module_tb/SDA

# -------------------------------------------------------------------------
# I2C Master
# -------------------------------------------------------------------------
add wave -divider "I2C Master"
add wave                               sim:/Top_Module_tb/uut/i2c_master/state
add wave                               sim:/Top_Module_tb/uut/i2c_master/busy
add wave                               sim:/Top_Module_tb/uut/i2c_master/done
add wave                               sim:/Top_Module_tb/uut/i2c_master/ack_error
add wave                               sim:/Top_Module_tb/uut/i2c_master/bus_error
add wave -radix hexadecimal            sim:/Top_Module_tb/uut/i2c_master/tx_data
add wave -radix hexadecimal            sim:/Top_Module_tb/uut/i2c_master/rx_data
add wave -radix hexadecimal            sim:/Top_Module_tb/uut/i2c_master/slave_addr

# -------------------------------------------------------------------------
# I2C Slave
# -------------------------------------------------------------------------
add wave -divider "I2C Slave"
add wave                               sim:/Top_Module_tb/uut/i2c_slave/state
add wave -radix hexadecimal            sim:/Top_Module_tb/uut/i2c_slave/rx_data

# -------------------------------------------------------------------------
# Layout / cosmetics
# -------------------------------------------------------------------------
configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -timelineunits ns

# Show the whole run first; zoom in on specific transactions manually
# (right-click-drag on the waveform, or use the commands below once you
# know roughly where a transaction of interest happens).
wave zoom full

# ---------------------------------------------------------------------------
# Suggested zoomed views (section 21 of the spec asks for these explicitly).
# These are commented out because the exact time window depends on your
# run -- after "run -all", scroll/zoom to the region you want in the GUI,
# note the start/end time shown at the bottom of the Wave window, then
# either zoom interactively or uncomment+edit a line below and re-source
# this file (or just type the command directly at the VSIM> prompt):
#
#   wave zoom range <start_time_ns> <end_time_ns>
#
# Useful checkpoints to look for on the timeline:
#   1. First APB write burst (SLAVE_ADDR/TX_DATA/CTRL)   -- near the start
#   2. First SDA falling edge while SCL is high          -- START condition
#   3. The following 8 SCL pulses                        -- address + R/W
#   4. The 9th SCL pulse                                  -- ACK
#   5. The next 8 SCL pulses                              -- data byte
#   6. The 9th SCL pulse                                  -- data ACK
#   7. SDA rising edge while SCL is high                  -- STOP condition
# -------------------------------------------------------------------------
