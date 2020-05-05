create_clock -name clk -period 20 [get_ports clk]

derive_clock_uncertainty

# constrain I/O ports
set_false_path -from * -to [get_ports {key*}]
set_false_path -from * -to [get_ports {led*}]
set_false_path -from * -to [get_ports {cols*}]
set_false_path -from * -to [get_ports {rows*}]
