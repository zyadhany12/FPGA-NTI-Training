# ============================================
# Step 1 : compile + start the simulation
#   usage:  do run_apb_i2c.do
# ============================================
vlib work
vlog +cover -covercells apb_i2c_pkg.sv apb_i2c_regs.sv apb_i2c_tb.sv
vsim -voptargs=+acc -coverage work.apb_i2c_tb
log -r /*
add wave *
run -all