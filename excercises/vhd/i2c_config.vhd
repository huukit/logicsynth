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
use ieee.numeric_std.all;
use ieee.math_real.all;

entity i2c_config is
    generic(
        ref_clk_freq_g  : integer := 50000000;
        i2c_freq_g      : integer := 20000;
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
    
    constant prescaler_max      : integer := (ref_clk_freq_g / i2c_freq_g) / 2;

    signal sclk_out_r           : std_logic;
    signal sclk_out_prescaler   : unsigned(integer(ceil(log2(real(prescaler_max)))) downto 0);

begin

    sclk_out <= sclk_out_r;

    generate_sclk_out : process(clk, rst_n)
    begin
        if(rst_n = '0') then
            sclk_out_r <= '0';
            sclk_out_prescaler <= (others => '0');
        elsif(clk'event and clk = '1') then
            if(sclk_out_prescaler = prescaler_max) then
                sclk_out_prescaler <= (others => '0');
                sclk_out_r <= not sclk_out_r;
            else
                sclk_out_prescaler <= sclk_out_prescaler + 1;
            end if;
        end if;
    end process generate_sclk_out;

end rtl;
