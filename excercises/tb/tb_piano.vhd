-------------------------------------------------------------------------------
-- Title      : Simple testbench for the audio synthesizer.
--              Note! No automatic checking!
--              You must "manually" check the waveforms, which is not nice.
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_piano.vhd
-- Author     : Erno Salminen  <ege@tiibetinhanhi.cs.tut.fi>
-- Company    : 
-- Last update: 2009/02/24
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2009/02/12  1.0      ege	Created (tb_synthesizer)
-- 10.2.2016   1.1      huukit  Imported from synth, and modified to support melody playing.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;


entity tb_piano is
  
end tb_piano;


architecture structural of tb_piano is

  component piano
    generic (
      clk_freq_g    : INTEGER;
      melody_clk_div: INTEGER;
      sample_rate_g : INTEGER;
      data_width_g  : INTEGER;
      n_keys_g      : INTEGER);
    port (
      clk           : IN  STD_LOGIC;
      rst_n         : IN  STD_LOGIC;
      keys_in       : IN  STD_LOGIC_VECTOR( n_keys_g-1 DOWNTO 0 );
      melody_in     : IN  STD_LOGIC;
      aud_bclk_out  : OUT STD_LOGIC;
      aud_lrclk_out : OUT STD_LOGIC;
      aud_data_out  : OUT STD_LOGIC);
  end component;

  component audio_codec_model
    generic (
      data_width_g : integer);
    port (
      rst_n           : in  std_logic;
      aud_bclk_in     : in  std_logic;
      aud_lrclk_in    : in  std_logic;
      aud_data_in     : in  std_logic;
      value_left_out  : out std_logic_vector(data_width_g-1 downto 0);
      value_right_out : out std_logic_vector(data_width_g-1 downto 0));
  end component;

  constant clk_freq_c    : integer := 20000000;
  constant melody_clk_c  : integer := 18432000 / 2;
  constant sample_rate_c : integer := 48000;
  constant data_width_c  : integer := 16;
  constant n_keys_c      : integer := 4;

  
  constant clk_period_c : time      := 50 ns;  -- i.e. 20 MHz
  signal   clk          : std_logic := '0';    -- global clock
  signal   rst_n        : std_logic := '0';    -- low active reset

  signal keys_tb_synth : std_logic_vector ( n_keys_c-1 downto 0);
  signal melody_key_synth : std_logic;
  
  signal aud_bclk_synth_model  : std_logic;
  signal aud_lrclk_synth_model : std_logic;
  signal aud_data_synth_model  : std_logic;
  signal value_left_model_tb   : std_logic_vector ( data_width_c-1 downto 0);
  signal value_right_model_tb  : std_logic_vector ( data_width_c-1 downto 0);


  signal   counter_r       : integer;
  constant button_period_c : integer := 2**data_width_c; 
  

  
begin  -- structural

  

  clk   <= not clk after clk_period_c/2;  -- kellon generointi
  rst_n <= '1'     after 4*clk_period_c;  -- reset pois nelj�n kellojakson j�lkeen

  i_duv_synth: piano
    generic map (
        clk_freq_g    => clk_freq_c,
        melody_clk_div=> melody_clk_c,
        sample_rate_g => sample_rate_c,
        data_width_g  => data_width_c,
        n_keys_g      => n_keys_c
        )
    port map (
        clk           => clk,
        rst_n         => rst_n,
        keys_in       => keys_tb_synth,
        melody_in     => melody_key_synth,
        aud_bclk_out  => aud_bclk_synth_model,
        aud_lrclk_out => aud_lrclk_synth_model,
        aud_data_out  => aud_data_synth_model
        );
  
  
  i_acm: audio_codec_model
    generic map (
        data_width_g => data_width_c)
    port map (
        rst_n           => rst_n,
        aud_bclk_in     => aud_bclk_synth_model,
        aud_lrclk_in    => aud_lrclk_synth_model,
        aud_data_in     => aud_data_synth_model,
        value_left_out  => value_left_model_tb,
        value_right_out => value_right_model_tb
        );
  

  press_buttons: process (clk, rst_n)
  begin  -- process press_buttons
    if rst_n = '0' then                 -- asynchronous reset (active low)

      counter_r     <= 0;
      keys_tb_synth <= (others => '1');
      melody_key_synth <= '0';
    elsif clk'event and clk = '1' then  -- rising clock edge

      if counter_r = button_period_c then
        counter_r     <= 0;
--        keys_tb_synth <= not std_logic_vector (unsigned(not keys_tb_synth)+1);
        keys_tb_synth <= std_logic_vector (unsigned(keys_tb_synth)-1);
        if( unsigned(keys_tb_synth) = 0) then
          melody_key_synth <= not melody_key_synth;
        end if;
      else
        counter_r <= counter_r + 1;
      end if;

      
    end if;
  end process press_buttons;

  
end structural;
