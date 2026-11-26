# RTL Compiler and Innovus scripts

Run from /home/svf168/finalproject with the four multicycle_*.v files, slow.lib, all.lef and an empty rpt/ folder.

    mkdir -p rpt
    rc -f design_unoptimized.g
    innovus        # then load innovus_unoptimized.conf

Repeat with predecode, or_select and optimized. Each run writes its own netlist and SDC, so results stay separate.

The clock period in each .g is in ps (10000 = 100 MHz). All four variants must use the same period for a fair comparison.
The core has no memories or pads, so memory data comes in through top-level ports.
Do not feed the multicycle_*.v files directly to Innovus.
