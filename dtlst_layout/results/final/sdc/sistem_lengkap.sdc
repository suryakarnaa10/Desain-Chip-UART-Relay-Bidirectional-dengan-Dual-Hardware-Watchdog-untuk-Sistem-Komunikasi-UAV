###############################################################################
# Created by write_sdc
# Sat Jun 20 15:34:15 2026
###############################################################################
current_design sistem_lengkap
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 8.0000 [get_ports {clk}]
set_clock_transition 0.1500 [get_clocks {clk}]
set_clock_uncertainty 0.2500 clk
set_propagated_clock [get_clocks {clk}]
set_input_delay 1.6000 -clock [get_clocks {clk}] -add_delay [get_ports {heartbeat_fc}]
set_input_delay 1.6000 -clock [get_clocks {clk}] -add_delay [get_ports {heartbeat_jetson}]
set_input_delay 1.6000 -clock [get_clocks {clk}] -add_delay [get_ports {initialize}]
set_input_delay 1.6000 -clock [get_clocks {clk}] -add_delay [get_ports {rxd_jetson}]
set_input_delay 1.6000 -clock [get_clocks {clk}] -add_delay [get_ports {rxd_raspi}]
set_output_delay 1.6000 -clock [get_clocks {clk}] -add_delay [get_ports {reset_n_fc}]
set_output_delay 1.6000 -clock [get_clocks {clk}] -add_delay [get_ports {txd_jetson}]
set_output_delay 1.6000 -clock [get_clocks {clk}] -add_delay [get_ports {txd_raspi}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.0334 [get_ports {reset_n_fc}]
set_load -pin_load 0.0334 [get_ports {txd_jetson}]
set_load -pin_load 0.0334 [get_ports {txd_raspi}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {clk}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {heartbeat_fc}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {heartbeat_jetson}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {initialize}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rxd_jetson}]
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin {Y} -input_transition_rise 0.0000 -input_transition_fall 0.0000 [get_ports {rxd_raspi}]
set_timing_derate -early 0.9500
set_timing_derate -late 1.0500
###############################################################################
# Design Rules
###############################################################################
set_max_transition 0.7500 [current_design]
set_max_fanout 10.0000 [current_design]
