set ::env(DESIGN_NAME) {sistem_lengkap}
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.v]
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "8.0"
set ::env(DESIGN_IS_CORE) {1}
