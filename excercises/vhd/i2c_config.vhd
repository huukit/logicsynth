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

    type state_type is (start_condition, stop_condition, acknowledge, data_transfer);
    type transmission_data_arr is array (n_params_g - 1 downto 0) of std_logic_vector(15 downto 0);
    type temp_transmission_arr is array (2 downto 0) of std_logic_vector(7 downto 0);
    
    constant prescaler_max_c    : integer := (ref_clk_freq_g / i2c_freq_g) / 2;
    constant codec_address_c    : std_logic_vector(7 downto 0) := "00110100";
    constant transmission_data_c  : transmission_data_arr := (
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

    signal sclk_r                   : std_logic;
    signal sclk_prescaler_r         : unsigned(integer(ceil(log2(real(prescaler_max_c)))) downto 0);
    signal present_state_r          : state_type;
    signal next_state_r             : state_type;
    signal bit_counter_r            : unsigned(2 downto 0);
    signal data_counter_r           : unsigned(1 downto 0);
    signal status_counter_r         : unsigned(3 downto 0);
    signal param_status_r           : std_logic_vector(n_params_g - 1 downto 0);
    signal temp_transmission_r      : temp_transmission_arr;


    signal sdat_r                   : std_logic;

begin

    sclk_out <= sclk_r;
    finished_out <= param_status_r(n_params_g - 1);
    -- sdat_inout <= sdat_r;
    sdat_r <= sdat_inout;
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
            sdat_inout <= 'Z';
            present_state_r <= start_condition;
            next_state_r <= start_condition;
            bit_counter_r <= to_unsigned(7, bit_counter_r'length);
            data_counter_r <= to_unsigned(0, data_counter_r'length);
            status_counter_r <= to_unsigned(0, status_counter_r'length);
            param_status_r <= (others => '0');
            temp_transmission_r(0) <= (others => '0');
            temp_transmission_r(1) <= (others => '0');
            temp_transmission_r(2) <= (others => '0');

        elsif(clk'event and clk = '1') then
            if(sclk_prescaler_r = prescaler_max_c / 2) then
                if(sclk_r = '1') then
                    present_state_r <= next_state_r;
                    if(next_state_r = acknowledge) then
                        sdat_inout <= 'Z';
                    end if;
                end if;

                case present_state_r is 
                    when start_condition =>
                        if(sdat_inout = '1' and sclk_r = '1') then
                            sdat_inout <= '0';
                            next_state_r <= data_transfer;
                            present_state_r <= data_transfer;
                            bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                            data_counter_r <= to_unsigned(0, data_counter_r'length);
                            temp_transmission_r(0) <= codec_address_c;
                            temp_transmission_r(1) <= transmission_data_c(to_integer(status_counter_r))(15 downto 8);
                            temp_transmission_r(2) <= transmission_data_c(to_integer(status_counter_r))(7 downto 0);
                        elsif(sclk_r = '0' and next_state_r = start_condition) then
                            sdat_inout <= '1';
                        end if;

                    when stop_condition =>
                        if(sdat_inout = '0' and sclk_r = '1') then
                            sdat_inout <= '1';
                            if(status_counter_r = n_params_g - 1) then
                                param_status_r(to_integer(status_counter_r)) <= '1';
                            else
                                next_state_r <= start_condition;
                            end if;
                        -- elsif((sdat_inout = '1' or sdat_inout = 'Z') and sclk_r = '0') then
                            -- sdat_inout <= '0';
                        -- else
                        elsif(sdat_inout = 'Z') then
                            sdat_inout <= '0';
                            -- sdat_inout <= 'Z';
                        end if;

                    when acknowledge =>
                        if(sclk_r = '1') then
                            -- present_state_r <= data_transfer;
                            -- bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                            -- data_counter_r <= data_counter_r + 1;
                            if(sdat_inout = '1') then
                                next_state_r <= start_condition;
                                bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                            elsif(sdat_inout = '0') then
                                if(data_counter_r = 2) then
                                    next_state_r <= stop_condition;
                                    bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                                    status_counter_r <= status_counter_r + 1;
                                    param_status_r(to_integer(status_counter_r)) <= '1';
                                else
                                    next_state_r <= data_transfer;
                                    present_state_r <= data_transfer;
                                    bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                                    data_counter_r <= data_counter_r + 1;
                                end if;
                            end if;
                        -- else    -- sclk_r = '0'
                            -- sdat_inout <= 'Z';
                        end if;

                    when data_transfer =>
                        if(sclk_r = '0') then
                            sdat_inout <= temp_transmission_r(to_integer(data_counter_r))(to_integer(bit_counter_r));
                            if(bit_counter_r = 0) then
                                -- bit_counter_r <= to_unsigned(7, 3);
                                -- next_state_r <= acknowledge;
                            else
                                bit_counter_r <= bit_counter_r - 1;
                            end if;
                        else
                            if(bit_counter_r = 0) then
                                bit_counter_r <= to_unsigned(7, 3);
                                next_state_r <= acknowledge;
                            end if;
                        end if;

                end case;
            end if;

        end if;

    end process generate_sdat;

end rtl;
