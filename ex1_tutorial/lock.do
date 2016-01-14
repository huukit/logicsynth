view source
view objects
view variables
view wave -undock

delete wave *
add wave *
add wave /sttran/count_v
property wave -radix unsigned /lock/keys_in

force -deposit /rst_n 0 0, 1 45
force -deposit /clk 1 0, 0 10 -r 20
force -deposit /keys_in 0000 0
run 100
force -deposit /keys_in 10#4, 10#1 20, 10#6 40, 10#9 60, 10#0 80
run 200
force -deposit /keys_in 10#2, 10#5 20, 10#4 40, 10#1 60, 10#6 80, 10#9 100, 10#1 120, 10#8 140, 10#0 160
run 300
force -deposit /keys_in 10#4, 10#1 20, 10#9 60, 10#0 80