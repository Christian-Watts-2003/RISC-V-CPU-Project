set_attribute library /home/kvi026/Innovus_tutorial/slow.lib
read_hdl /home/kvi026/Innovus_tutorial/mux.v 
elaborate
synthesize -to_mapped
report timing >> /home/kvi026/Innovus_tutorial/mux_time.rpt  
report area >> /home/kvi026/Innovus_tutorial/mux_area.rpt
write_hdl >> /home/kvi026/Innovus_tutorial/mux_Net.v
report power >> /home/kvi026/Innovus_tutorial/mux_pwr.rpt

