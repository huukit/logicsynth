-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 08
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : Jonas Nikula, Tuomas Huuki
-- Company    : TUT
-- Created    : 11.01.2016
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Controller for Wolfson WM8731 -audio codec
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date         Version     Author          Description
-- 11.01.2016   1.0         nikulaj         Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_ctrl is
    generic
    (
    ref_clk_freq_g  : integer := 18 432 000;
    sample_rate_g   : integer := 48 000;
    data_width_g    : integer := 16;
    );

    port
    (
    clk             : in std_logic;
    rst_n           : in std_logic;
    left_data_in    : in std_logic_vector(data_width_g - 1 downto 0);
    right_data_in   : in std_logic_vector(data_width_g - 1 downto 0);

    aud_bclk_out    : out std_logic;
    aud_data_out    : out std_logic;
    aud_lrclk_out   : out std_logic;
    );
end audio_ctrl;

architecture rtl of audio_ctrl is
-- signal declarations go here
begin
-- logic goes here
end rtl;
