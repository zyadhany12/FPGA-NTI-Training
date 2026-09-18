# ============================================
# Step 2 : after the run breaks at $stop,
#          save the databases and write reports
#   usage:  do save_cov.do
# ============================================
# full database: design code coverage + covergroups
coverage save apb_i2c_tb.ucdb
# design-only database (code coverage of the DUT, no testbench noise)
coverage save apb_i2c_code.ucdb -du apb_i2c_regs
quit -sim
# ---------- report 1 : code coverage (design only) ----------
vcover report apb_i2c_code.ucdb -details -annotate -all -output code_coverage_rpt.txt
# ---------- report 2 : functional coverage (covergroups) ----------
vcover report apb_i2c_tb.ucdb -cvg -details -output functional_coverage_rpt.txt