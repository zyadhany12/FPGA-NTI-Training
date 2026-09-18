# =============================================================================
# run_i2c_master.do
# ModelSim / Questa script: compile i2c_master + testbench, run, view waves.
# Usage (from the tool's command line):
#     vsim -do run_i2c_master.do
# =============================================================================

quit -sim
if {[file exists work]} { vdel -all }
vlib work
vmap work work

# ---- Compile DUT and testbench ----
vlog -sv +acc ../src/i2c_master.sv
vlog -sv +acc i2c_master_tb.sv

# ---- Elaborate / load ----
vsim -voptargs=+acc work.i2c_master_tb

# ---- Waves ----
add wave -divider "Control / Status"
add wave -radix binary   sim:/i2c_master_tb/clk
add wave -radix binary   sim:/i2c_master_tb/rst_n
add wave -radix binary   sim:/i2c_master_tb/start
add wave -radix binary   sim:/i2c_master_tb/rw
add wave -radix hex      sim:/i2c_master_tb/slave_addr
add wave -radix hex      sim:/i2c_master_tb/tx_data
add wave -radix hex      sim:/i2c_master_tb/rx_data
add wave -radix binary   sim:/i2c_master_tb/busy
add wave -radix binary   sim:/i2c_master_tb/done
add wave -radix binary   sim:/i2c_master_tb/ack_error
add wave -radix binary   sim:/i2c_master_tb/bus_error

add wave -divider "I2C Bus"
add wave -radix binary   sim:/i2c_master_tb/sda_bus
add wave -radix binary   sim:/i2c_master_tb/scl_bus

add wave -divider "DUT internals"
add wave -radix symbolic sim:/i2c_master_tb/dut/state
add wave -radix hex      sim:/i2c_master_tb/dut/bit_count
add wave -radix hex      sim:/i2c_master_tb/dut/tx_shift
add wave -radix hex      sim:/i2c_master_tb/dut/rx_shift
add wave -radix binary   sim:/i2c_master_tb/dut/sda_drive_low
add wave -radix binary   sim:/i2c_master_tb/dut/scl_drive_low
add wave -radix binary   sim:/i2c_master_tb/dut/i2c_tick

add wave -divider "Slave BFM (testbench)"
add wave -radix binary   sim:/i2c_master_tb/slave_sda_low
add wave -radix hex      sim:/i2c_master_tb/last_rx_byte
add wave -radix hex      sim:/i2c_master_tb/slave_tx_data

configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -timelineunits ns

# ---- Run to completion ($finish in the testbench ends the run) ----
run -all

wave zoom full
