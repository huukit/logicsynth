-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 08
-- Project    :
-------------------------------------------------------------------------------
-- File       : synthesizer.vhd
-- Author     : Jonas Nikula, Tuomas Huuki
-- Company    : TUT
-- Created    : 14.1.2016
-- Platform   :
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Synthesizer structural description
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date             Version     Author          Description
-- 14.01.2016       1.0         nikulaj         Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity synthesizer is 
    generic
    (
    clk_freq_g      : integer := 18432000;
    sample_rate_g   : integer := 48000;
    data_width_g    : integer := 16;
    n_keys_g        : integer := 4
    );

    port
    (
    clk               : in std_logic;
    rst_n             : in std_logic;
    keys_in           : in std_logic_vector(n_keys_g - 1 downto 0);
    aud_bclk_out      : out std_logic;
    aud_data_out      : out std_logic;
    aud_lrclk_out     : out std_logic
    );
end synthesizer;

architecture rtl of synthesizer is
    component wave_gen is
        generic
        (
            width_g             : integer; -- Width of the generated wave in bits.
            step_g              : integer -- Width of one step.
        );
        port
        (
            clk                 : in std_logic; -- Clock signal.
            rst_n               : in std_logic; -- Reset, actove low.
            sync_clear_in       : in std_logic; -- Sync bit input to clear the counter.
            value_out           : out std_logic_vector(width_g - 1 downto 0)  -- Counter value out.
        );
    end component;

    component multi_port_adder is
        generic
        (
            operand_width_g     : integer := 16; -- Specify default value for both.
            num_of_operands_g   : integer := 4
        );
        port
        (
            clk         : in std_logic; -- Clock signal.
            rst_n       : in std_logic; -- Reset, active low.
            operands_in : in std_logic_vector((operand_width_g * num_of_operands_g) - 1 downto 0); -- Operand inputs
            sum_out     : out std_logic_vector(operand_width_g - 1 downto 0) -- Calculation result.
        );
    end component;

    component audio_ctrl is
        generic
        (
            ref_clk_freq_g  : integer := 18432000;  -- Reference clock.
            sample_rate_g   : integer := 48000;     -- Sample clock fs.
            data_width_g    : integer := 16         -- Data width.
        );
        port
        (
            clk             : in std_logic;         -- Main clock.
            rst_n           : in std_logic;         -- Reset, active low.
            left_data_in    : in std_logic_vector(data_width_g - 1 downto 0); -- Data in, left.
            right_data_in   : in std_logic_vector(data_width_g - 1 downto 0); -- Data in, right.
            aud_bclk_out    : out std_logic;        -- Audio bitclock.
            aud_data_out    : out std_logic;        -- Audio data.
            aud_lrclk_out   : out std_logic         -- Audio bitclock L/R select.
        );
    end component;

    signal adder_input_r    : std_logic_vector((data_width_g * n_keys_g)-1 downto 0);

begin -- rtl
    wave_generators:
    for I in 0 to n_keys_g - 1 generate
        wavegen_arr : wave_gen
        generic map
        (
            width_g => data_width_g,
            step_g => 2**I
        )
        port map
        (
            clk => clk,
            rst_n => rst_n,
            sync_clear_in => keys_in(I),
            value_out => adder_input_r((I+1)*data_width_g - 1 downto I*data_width_g)
        );
    end generate wave_generators;


end rtl;
