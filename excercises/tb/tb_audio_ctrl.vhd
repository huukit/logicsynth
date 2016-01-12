-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 09
-- Project    :
-------------------------------------------------------------------------------
-- File       : tb_audio_ctrl.vhd
-- Author     : Tuomas Huuki
-- Company    : TUT
-- Created    : 11.1.2016
-- Platform   :
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Ninth excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 11.1.2016   1.0      tuhu    Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity tb_audio_ctrl is
  generic(
    data_width_g    : integer := 16
  );
end tb_audio_ctrl;

architecture testbench of tb_audio_ctrl is
  
  constant clockrate_ns_c : time := 54 ns;
  
  signal clk              : std_logic := '0';
  signal rst_n            : std_logic := '0';
  signal left_data_in_r   : std_logic_vector(data_width_g - 1 downto 0);
  signal right_data_in_r  : std_logic_vector(data_width_g - 1 downto 0);
  signal aud_bclk_out_r   : std_logic;
  signal aud_data_out_r   : std_logic;
  signal aud_lrclk_out_r  : std_logic;
  
  component audio_ctrl is
    generic(
      ref_clk_freq_g  : integer := 18432000;
      sample_rate_g   : integer := 48000;
      data_width_g    : integer := 16
    );
    
    port(
      clk             : in std_logic;
      rst_n           : in std_logic;
      left_data_in    : in std_logic_vector(data_width_g - 1 downto 0);
      right_data_in   : in std_logic_vector(data_width_g - 1 downto 0);
      aud_bclk_out    : out std_logic;
      aud_data_out    : out std_logic;
      aud_lrclk_out   : out std_logic
    );
  end component;
  
begin -- testbench
  i_acontrol : audio_ctrl
    generic map(
      data_width_g => data_width_g
    )
    port map(
      rst_n => rst_n,
      clk => clk,
      left_data_in => left_data_in_r,
      right_data_in => right_data_in_r     
    );
     
  clk <= not clk after clockrate_ns_c/2; -- Create clock pulse.
  rst_n <= '1' after clockrate_ns_c * 4; -- Reset high after 4 pulses.
  
  data_generator : process(clk, rst_n)
  begin
    if(rst_n = '0') then
      left_data_in_r <= (others => '0');
      right_data_in_r <= (others => '0');
    elsif(clk'event and clk = '1') then
      -- Generate data ..
    end if;
  end process data_generator;
  
end testbench;