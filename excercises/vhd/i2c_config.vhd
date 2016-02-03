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
-- 03.02.2016       1.1         huukitu         Moved data to pkg, added comments.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.i2c_data_pkg.all; -- Separate package for data so that the this file does not
                           -- have to be edited if the data is changed.

-- Entity and connections.
entity i2c_config is
    generic(
        ref_clk_freq_g  : integer := 50000000;  -- Reference clock of system.
        i2c_freq_g      : integer := 20000;     -- Clock of i2c bus.
        n_params_g      : integer := params_g   -- Number of parameters to send.
    );
    port(
        clk                 : in    std_logic;  -- Clcok
        rst_n               : in    std_logic;  -- Reset, active low.
        sdat_inout          : inout std_logic;  -- In/out pin of i2c data.
        sclk_out            : out   std_logic;  -- I2c clock.
        -- Debug helping outputs.
        param_status_out    : out   std_logic_vector(n_params_g - 1 downto 0);
        finished_out        : out   std_logic
    );
end i2c_config;

architecture rtl of i2c_config is
    -- States that the controller can have.
    type state_type is (start_condition, stop_condition, acknowledge, data_transfer);

    type temp_transmission_arr is array (2 downto 0) of std_logic_vector(7 downto 0);
    
    constant prescaler_max_c        : integer := (ref_clk_freq_g / i2c_freq_g) / 2;
    constant codec_address_c        : std_logic_vector(7 downto 0) := "00110100";
   
    signal sclk_r                   : std_logic; -- Register for i2c clock.
    signal sclk_prescaler_r         : unsigned(integer(ceil(log2(real(prescaler_max_c)))) downto 0); -- Clock prescaler value.
    signal present_state_r          : state_type; -- State register.
    signal bit_counter_r            : unsigned(2 downto 0); -- Counter for sent bits.
    signal byte_counter_r           : unsigned(1 downto 0); -- Counter for sent bytes.
    signal status_counter_r         : unsigned(3 downto 0); -- Counter for internal status.
    signal param_status_r           : std_logic_vector(n_params_g - 1 downto 0); -- Debug helper.
    signal temp_transmission_r      : temp_transmission_arr; -- Temporary transmission array.

begin
    
    -- Assign debug outputs to reflect the internal status.
    finished_out <= param_status_r(n_params_g - 1);
    param_status_out <= param_status_r;

    -- Set sckl to 'Z' after transmission has ended.
    with param_status_r(n_params_g - 1) select
        sclk_out <=
        sclk_r when '0',
        'Z'    when others;

    -- i2c clock generation process.
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

    -- Data generation.
    generate_sdat : process(clk, rst_n)
    begin
        if(rst_n = '0') then
            sdat_inout <= 'Z';
            present_state_r <= start_condition;
            bit_counter_r <= to_unsigned(7, bit_counter_r'length);
            byte_counter_r <= to_unsigned(0, byte_counter_r'length);
            status_counter_r <= to_unsigned(0, status_counter_r'length);
            param_status_r <= (others => '0');
            temp_transmission_r(0) <= (others => '0');
            temp_transmission_r(1) <= (others => '0');
            temp_transmission_r(2) <= (others => '0');

        elsif(clk'event and clk = '1') then
            if(present_state_r = acknowledge and sclk_prescaler_r = 0) then
                sdat_inout <= 'Z';
            end if;
            if(param_status_r(n_params_g - 1) = '1') then
                sdat_inout <= 'Z';
            elsif(sclk_prescaler_r = prescaler_max_c / 2) then

                case present_state_r is 
                    when start_condition =>
                        if(sdat_inout = '1' and sclk_r = '1') then
                            sdat_inout <= '0';
                            present_state_r <= data_transfer;
                            bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                            byte_counter_r <= to_unsigned(0, byte_counter_r'length);
                            temp_transmission_r(0) <= codec_address_c;
                            temp_transmission_r(1) <= transmission_data_c(to_integer(status_counter_r))(15 downto 8);
                            temp_transmission_r(2) <= transmission_data_c(to_integer(status_counter_r))(7 downto 0);
                        elsif(sclk_r = '0' and present_state_r = start_condition) then
                            sdat_inout <= '1';
                        end if;

                    when stop_condition =>
                        if(sdat_inout = '0' and sclk_r = '1') then
                            sdat_inout <= '1';
                            status_counter_r <= status_counter_r + 1;
                            param_status_r(to_integer(status_counter_r)) <= '1';
                        elsif(sdat_inout = '1' and sclk_r = '0') then
                            present_state_r <= start_condition;
                        elsif(sdat_inout = 'Z') then
                            sdat_inout <= '0';
                        end if;

                    when acknowledge =>
                        bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                        if(sclk_r = '1') then
                            if(sdat_inout = '1') then
                                present_state_r <= start_condition;
                            elsif(sdat_inout = '0') then
                                if(byte_counter_r = 2) then
                                    present_state_r <= stop_condition;
                                else
                                    present_state_r <= data_transfer;
                                    byte_counter_r <= byte_counter_r + 1;
                                end if;
                            end if;
                        end if;

                    when data_transfer =>
                        if(sclk_r = '0') then
                            sdat_inout <= temp_transmission_r(to_integer(byte_counter_r))(to_integer(bit_counter_r));
                        else
                            if(bit_counter_r = 0) then
                                present_state_r <= acknowledge;
                            else
                                bit_counter_r <= bit_counter_r - 1;
                            end if;
                        end if;

                end case;
            end if;

        end if;

    end process generate_sdat;

end rtl;
