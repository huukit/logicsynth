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
    clk_freq_g      : integer 18432000;
    sample_rate_g   : integer 48000;
    data_width_g    : integer 16;
    n_keys_g        : integer 4
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
begin -- rtl
end rtl;
