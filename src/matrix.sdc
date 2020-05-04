create_clock -name clk -period 20 [get_ports clk]

derive_pll_clocks
create_generated_clock -name sdram_clk -source [get_pins {pll|altpll_component|auto_generated|pll1|clk[1]}] [get_ports sdram_clk]
derive_clock_uncertainty

# this is tAC in the data sheet
set_input_delay -max -clock sdram_clk 6 [get_ports sdram_dq[*]]

# this is tOH in the data sheet
set_input_delay -min -clock sdram_clk 2.5 [get_ports sdram_dq[*]]

# this is tIS in the data sheet (setup time)
set_output_delay -max -clock sdram_clk 1.5 [get_ports sdram_*]

# this is tIH in the data sheet (hold time)
set_output_delay -min -clock sdram_clk 1.5 [get_ports sdram_*]

# constrain input ports
set_false_path -from * -to [get_ports {key*}]

# constrain output ports
set_false_path -from * -to [get_ports {led*}]
