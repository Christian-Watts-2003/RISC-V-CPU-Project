set_attribute library /home/svf168/finalproject/slow.lib
read_hdl /home/svf168/finalproject/multicycle_or_select.v
elaborate rv32i_multicycle

# period in ps, edit to sweep target frequency
define_clock -name clk -period 10000 [find / -port clk]

synthesize -to_mapped
report timing >> /home/svf168/finalproject/rpt/or_select_time.rpt
report area >> /home/svf168/finalproject/rpt/or_select_area.rpt
report power >> /home/svf168/finalproject/rpt/or_select_pwr.rpt
write_hdl > /home/svf168/finalproject/or_select_Net.v
write_sdc > /home/svf168/finalproject/or_select.sdc
exit
