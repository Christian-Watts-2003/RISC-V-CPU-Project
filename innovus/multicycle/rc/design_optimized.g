set_attribute library /home/svf168/finalproject/slow.lib
read_hdl /home/svf168/finalproject/multicycle_optimized.v
elaborate rv32i_multicycle

# period in ps, edit to sweep target frequency
define_clock -name clk -period 10000 [find / -port clk]

synthesize -to_mapped
report timing >> /home/svf168/finalproject/rpt/optimized_time.rpt
report area >> /home/svf168/finalproject/rpt/optimized_area.rpt
report power >> /home/svf168/finalproject/rpt/optimized_pwr.rpt
write_hdl > /home/svf168/finalproject/optimized_Net.v
write_sdc > /home/svf168/finalproject/optimized.sdc
exit
