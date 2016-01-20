-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 12
-- Project    :
-------------------------------------------------------------------------------
-- File       : i2c_config.vhd
-- Author     : Jonas Nikula, Tuomas Huuki
-- Company    : TUT
-- Created    : 20.1.2016
-- Platform   :
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: I2C bus controller, for Wolfson Audio Codec configuration 
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date             Version     Author          Description
-- 20.01.2016       1.0         nikulaj         Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity i2c_config is
    generic(
        ref_clk_freq_g  : integer := 50 000 000;
        i2c_freq_g      : integer := 20 000;
        n_params_g      : integer := 10
    );
    port(
        clk                 : in    std_logic;
        rst_n               : in    std_logic;
        sdat_inout          : inout std_logic;
        sclk_out            : out   std_logic;
        param_status_out    : out   std_logic_vector(n_params_g - 1 downto 0);
        finished_out        : out   std_logic
    );
end i2c_config;

architecture rtl of i2c_config is

begin

end rtl;
