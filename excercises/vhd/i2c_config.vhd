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
    
    constant prescaler_max_c    : integer := (ref_clk_freq_g / i2c_freq_g) / 2;

    signal sclk_r               : std_logic;
    signal sclk_prescaler_r     : unsigned(integer(ceil(log2(real(prescaler_max_c)))) downto 0);

    signal sdat_r               : std_logic;

    type state_type is (start_condition, stop_condition,
                        acknowledge, address_transfer, data_transfer);
    signal present_state_r      : state_type;
    signal next_state_r         : state_type;

    signal bit_counter_r        : unsigned(2 downto 0);

    signal status_counter_r     : unsigned(3 downto 0);
    signal param_status_r       : std_logic_vector(n_params_g - 1 downto 0);

    signal temp_address_r       : std_logic_vector(7 downto 0);
    signal temp_data_r          : std_logic_vector(7 downto 0);
    type transmission_arr is array (n_params_g - 1 downto 0) of std_logic_vector(15 downto 0);
    signal transmission_c       : transmission_arr :=   (
                                                        "0001001000000001",
                                                        "0001000XXXXXXXXX",
                                                        "0000111XXXXXXXXX",
                                                        "0000110000000000",
                                                        "0000101000000110",
                                                        "0000100011111000",
                                                        "0000011001111011",
                                                        "0000010001111011",
                                                        "0000001000011010",
                                                        "0000000000011010"
                                                        );

begin

    sclk_out <= sclk_r;
    finished_out <= param_status_r(n_params_g - 1);
    sdat_inout <= sdat_r;
    param_status_out <= param_status_r;

    generate_sclk : process(clk, rst_n)
    begin
        if(rst_n = '0') then
            sclk_r <= '0';
            sclk_prescaler_r <= (others => '0');
        elsif(clk'event and clk = '1') then
            if(sclk_prescaler_r = prescaler_max_c) then
                sclk_prescaler_r <= (others => '0');
                sclk_r <= not sclk_r;
            else
                sclk_prescaler_r <= sclk_prescaler_r + 1;
            end if;
        end if;
    end process generate_sclk;

    generate_sdat : process(clk, rst_n)
    begin
        if(rst_n = '0') then
            sdat_r <= 'Z';
            present_state_r <= start_condition;
            next_state_r <= start_condition;
            bit_counter_r <= to_unsigned(7, bit_counter_r'length);
            status_counter_r <= to_unsigned(0, status_counter_r'length);
            param_status_r <= (others => '0');

        elsif(clk'event and clk = '1') then

            case present_state_r is 

                when start_condition =>
                    if(sdat_r = '1' and sclk_r = '1' and sclk_prescaler_r = prescaler_max_c / 2) then
                        sdat_r <= '0';
                        present_state_r <= address_transfer;
                        temp_address_r <= transmission_c(to_integer(status_counter_r))(15 downto 8);
                        temp_data_r <= transmission_c(to_integer(status_counter_r))(7 downto 0);
                    elsif((sdat_r = '0' or sdat_r = 'Z') and sclk_prescaler_r = prescaler_max_c / 2) then
                        sdat_r <= '1';
                    end if;

                when stop_condition =>
                    if(sdat_r = '0' and sclk_r = '1' and sclk_prescaler_r = prescaler_max_c / 2) then
                        sdat_r <= '1';
                        param_status_r(to_integer(status_counter_r)) <= '1';
                    elsif((sdat_r = '1' or sdat_r = 'Z') and sclk_prescaler_r = prescaler_max_c / 2) then
                        sdat_r <= '0';
                    elsif(sclk_prescaler_r = prescaler_max_c / 2) then
                        sdat_r <= 'Z';
                    end if;

                when acknowledge =>
                    if(sclk_r = '0' and sclk_prescaler_r = prescaler_max_c / 2) then
                        if(param_status_r(n_params_g - 1) = '1') then
                            present_state_r <= stop_condition;
                        else
                            present_state_r <= next_state_r;
                            if(next_state_r = start_condition) then
                                param_status_r(to_integer(status_counter_r)) <= '1';
                                status_counter_r <= status_counter_r + 1;
                            end if;
                        end if;
                        sdat_r <= 'Z';
                    end if;

                when address_transfer =>
                    if(sclk_r = '0' and sclk_prescaler_r = prescaler_max_c / 2) then
                        sdat_r <= temp_address_r(to_integer(bit_counter_r));
                        if(bit_counter_r = 0) then
                            bit_counter_r <= to_unsigned(7, 3);
                            present_state_r <= acknowledge;
                            next_state_r <= data_transfer;
                        else
                            bit_counter_r <= bit_counter_r - 1;
                        end if;
                    end if;

                when data_transfer =>
                    if(sclk_r = '0' and sclk_prescaler_r = prescaler_max_c / 2) then
                        sdat_r <= temp_data_r(to_integer(bit_counter_r));
                        if(bit_counter_r = 0 and status_counter_r = n_params_g - 1) then
                            present_state_r <= acknowledge;
                            next_state_r <= stop_condition;
                        elsif(bit_counter_r = 0) then
                            bit_counter_r <= to_unsigned(7, 3);
                            present_state_r <= acknowledge;
                            next_state_r <= start_condition;
                        else
                            bit_counter_r <= bit_counter_r - 1;
                        end if;
                    end if;

            end case;

        end if;

    end process generate_sdat;

end rtl;
