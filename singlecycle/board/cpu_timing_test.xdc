# Constraints for cpu_timing_test_top.
# Assign package pins only if this wrapper is used directly on hardware.

create_clock -name sys_clk -period 10.000 [get_ports clk]

# The instruction and load-data buses are treated as externally supplied
# combinational inputs for this timing-isolation experiment.
set_input_delay -clock sys_clk -min 0.000 [get_ports {reset instruction[*] mem_read_data[*]}]
set_input_delay -clock sys_clk -max 0.000 [get_ports {reset instruction[*] mem_read_data[*]}]

set_output_delay -clock sys_clk -min 0.000 \
    [get_ports {pc[*] mem_addr[*] mem_write_data[*] mem_write_strobe[*] mem_read mem_write}]
set_output_delay -clock sys_clk -max 0.000 \
    [get_ports {pc[*] mem_addr[*] mem_write_data[*] mem_write_strobe[*] mem_read mem_write}]
