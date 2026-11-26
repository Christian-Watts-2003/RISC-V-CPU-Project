set_attribute library /home/svf168/finalproject/slow.lib
read_hdl /home/svf168/finalproject/multicycle_unoptimized.v
elaborate rv32i_multicycle

# period in ps, edit to sweep target frequency
define_clock -name clk -period 10000 [find / -port clk]

synthesize -to_mapped
report timing >> /home/svf168/finalproject/rpt/unoptimized_time.rpt
report area >> /home/svf168/finalproject/rpt/unoptimized_area.rpt
report power >> /home/svf168/finalproject/rpt/unoptimized_pwr.rpt
write_hdl > /home/svf168/finalproject/unoptimized_Net.v
write_sdc > /home/svf168/finalproject/unoptimized.sdc
exit
