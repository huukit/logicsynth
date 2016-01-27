vsim my_lib.tb_i2c_config
add wave -position end  sim:/tb_i2c_config/i2c_config_1/sclk_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/sdat_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/present_state_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/bit_counter_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/data_counter_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/status_counter_r
add wave -position end  sim:/tb_i2c_config/i2c_config_1/temp_transmission_r

add wave -position 1  sim:/tb_i2c_config/sdat
add wave -position 0  sim:/tb_i2c_config/bit_counter_r
add wave -position 1  sim:/tb_i2c_config/byte_counter_r
add wave -position 2  sim:/tb_i2c_config/curr_state_r
add wave -position 3  sim:/tb_i2c_config/sdat_r