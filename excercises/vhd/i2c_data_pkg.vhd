library ieee;
use ieee.std_logic_1164.all;

package i2c_data_pkg is 
  constant params_g      : integer := 10;
  type transmission_data_arr is array (params_g - 1 downto 0) of std_logic_vector(15 downto 0);
  -- Actual transmission data array.
  constant transmission_data_c    : transmission_data_arr := (
                                                            "0001001000000001",
                                                            "0001000000000010",
                                                            "0000111000000001",
                                                            "0000110000000000",
                                                            "0000101000000110",
                                                            "0000100011111000",
                                                            "0000011001111011",
                                                            "0000010001111011",
                                                            "0000001000011010",
                                                            "0000000000011010"
                                                            );

end i2c_data_pkg;