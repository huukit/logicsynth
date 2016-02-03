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

-- define the entity
entity i2c_config is
    generic(
        ref_clk_freq_g  : integer := 50000000;      -- reference clk
        i2c_freq_g      : integer := 20000;         -- wanted i2c frequency
        n_params_g      : integer := 10             -- amount of 3 byte transmissions
    );
    port(
        clk                 : in    std_logic;
        rst_n               : in    std_logic;      -- active low rst
        sdat_inout          : inout std_logic;      -- i2c dataline
        sclk_out            : out   std_logic;      -- i2c clk
        param_status_out    : out   std_logic_vector(n_params_g - 1 downto 0);  -- status "display"
        finished_out        : out   std_logic       -- 1 when done sending
    );
end i2c_config;

architecture rtl of i2c_config is

    -- type definitions
    type state_type is (start_condition, stop_condition, acknowledge, data_transfer);
    type transmission_data_arr is array (n_params_g - 1 downto 0) of std_logic_vector(15 downto 0);
    type temp_transmission_arr is array (2 downto 0) of std_logic_vector(7 downto 0);
    
    -- constants
    -- max value for clk prescaler
    constant prescaler_max_c        : integer := (ref_clk_freq_g / i2c_freq_g) / 2;

    -- data to be sent
    constant codec_address_c        : std_logic_vector(7 downto 0) := "00110100";
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

    -- registers
    signal sclk_r                   : std_logic;
    signal sclk_prescaler_r         : unsigned(integer(ceil(log2(real(prescaler_max_c)))) downto 0);
    signal present_state_r          : state_type;
    signal bit_counter_r            : unsigned(2 downto 0);
    signal byte_counter_r           : unsigned(1 downto 0);
    signal status_counter_r         : unsigned(3 downto 0);
    signal param_status_r           : std_logic_vector(n_params_g - 1 downto 0);
    signal temp_transmission_r      : temp_transmission_arr;

begin

    -- assign the last bit of param_status to finished; When the last transmission
    -- is done, the config is finished.
    finished_out <= param_status_r(n_params_g - 1);
    param_status_out <= param_status_r;

    -- Only output clk when NOT finished
    with param_status_r(n_params_g - 1) select
        sclk_out <=
        sclk_r when '0',
        'Z'    when others;

    -- i2c clk generation process
    -- Increments counter, until it hits max value. At that point the clk
    -- changes value
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

    -- i2c data output process
    generate_sdat : process(clk, rst_n)
    begin
        if(rst_n = '0') then            -- reset all values that need it
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
            if(param_status_r(n_params_g - 1) = '1') then
                sdat_inout <= 'Z';          -- When finished, take config logic
                                            -- out of the circuit

            elsif(present_state_r = acknowledge and sclk_prescaler_r = 0) then
                sdat_inout <= 'Z';          -- set to high-Z, so that ack can be received

            elsif(sclk_prescaler_r = prescaler_max_c / 2) then

                case present_state_r is 
                    when start_condition =>
                        -- when sdat is high, a transition to low triggers a
                        -- start condition
                        -- also prepare for data transfer
                        if(sdat_inout = '1' and sclk_r = '1') then
                            sdat_inout <= '0';
                            present_state_r <= data_transfer;
                            bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                            byte_counter_r <= to_unsigned(0, byte_counter_r'length);
                            temp_transmission_r(0) <= codec_address_c;
                            temp_transmission_r(1) <= transmission_data_c(to_integer(status_counter_r))(15 downto 8);
                            temp_transmission_r(2) <= transmission_data_c(to_integer(status_counter_r))(7 downto 0);
                        elsif(sclk_r = '0' and present_state_r = start_condition) then
                            -- set sdat high so it can be pulled low
                            sdat_inout <= '1';
                        end if;

                    when stop_condition =>
                        if(sdat_inout = '0' and sclk_r = '1') then
                            -- when sdat is low, a transition to high
                            -- triggers a stop condition
                            sdat_inout <= '1';
                            -- 3 byte transfer is done, increment status
                            status_counter_r <= status_counter_r + 1;
                            param_status_r(to_integer(status_counter_r)) <= '1';
                        elsif(sdat_inout = '1' and sclk_r = '0') then
                            -- after stop cond, go to start
                            present_state_r <= start_condition;
                        elsif(sdat_inout = 'Z') then
                            sdat_inout <= '0';
                        end if;

                    when acknowledge =>
                        bit_counter_r <= to_unsigned(7, bit_counter_r'length);
                        -- listening for ack (or nack)
                        if(sclk_r = '1') then
                            if(sdat_inout = '1') then
                                -- on nack, go to start
                                present_state_r <= start_condition;
                            elsif(sdat_inout = '0') then
                                -- on ack, got to stop if all 3 bytes sent
                                if(byte_counter_r = 2) then
                                    present_state_r <= stop_condition;
                                -- otherwise to next byte
                                else
                                    present_state_r <= data_transfer;
                                    byte_counter_r <= byte_counter_r + 1;
                                end if;
                            end if;
                        end if;

                    when data_transfer =>
                        -- when clk is low, change state, so that line is
                        -- stable for high
                        if(sclk_r = '0') then
                            sdat_inout <= temp_transmission_r(to_integer(byte_counter_r))(to_integer(bit_counter_r));
                        else
                            -- When bit is being sent, check if whole byte is
                            -- sent. If so, go to ack, otherwise
                            -- increment bit counter.
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
