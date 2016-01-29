vsim my_lib.tb_i2c_config

add wave -position end  sim:/tb_i2c_config/sdat
add wave -position end  sim:/tb_i2c_config/bit_counter_r
add wave -position end  sim:/tb_i2c_config/byte_counter_r
add wave -position end  sim:/tb_i2c_config/curr_state_r
add wave -position end  sim:/tb_i2c_config/sdat_r

add wave -position end  sim:/tb_i2c_config/i2c_config_1/sclk_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/present_state_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/bit_counter_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/byte_counter_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/status_counter_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/temp_transmission_r

add wave -position end sim:/tb_i2c_config/temp_transmission_r

run 15ms
