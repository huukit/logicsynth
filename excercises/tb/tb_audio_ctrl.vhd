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
-- 11.1.2016   1.0      huukit  Created.
-- 15.1.2016   1.1      huukit  Added bonus feature.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Test bench entity.
entity tb_audio_ctrl is
  generic(
    data_width_g    : integer := 16;
    step_w_r_g      : integer := 2;
    step_w_l_g      : integer := 10;
    ref_clk_freq_g  : integer := 18432000;
    sample_rate_g   : integer := 48000
  );
end tb_audio_ctrl;

architecture testbench of tb_audio_ctrl is
  
  -- Component definitions.
  component audio_ctrl is
    generic(
      ref_clk_freq_g  : integer := 18432000;
      sample_rate_g   : integer := 48000;
      data_width_g    : integer
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
  
  component audio_codec_model is
  generic(
    data_width_g    : integer
  );
  port(
    rst_n           : in std_logic;
    aud_data_in     : in std_logic;
    aud_bclk_in     : in std_logic;
    aud_lrclk_in    : in std_logic;
    
    value_left_out  : out std_logic_vector(data_width_g - 1 downto 0);
    value_right_out : out std_logic_vector(data_width_g - 1 downto 0)
  );
  end component;

  component wave_gen is 
  generic (
    width_g             : integer;
    step_g              : integer := 1 
  );
  port(
    clk                 : in std_logic; 
    rst_n               : in std_logic; 
    sync_clear_in       : in std_logic; 
    value_out           : out std_logic_vector(width_g - 1 downto 0)
  );
  end component;
  
  -- Clock rate of simulation ~50 is ok.
  constant clockrate_ns_c : time := 50 ns;
  
  signal clk                : std_logic := '0'; -- Main clock.
  signal rst_n              : std_logic := '0'; -- Main reset.
  signal sync_r             : std_logic := '0'; -- Sync signal for generators.
  signal l_data_wg_actrl    : std_logic_vector(data_width_g - 1 downto 0); -- Generator output.
  signal r_data_wg_actrl    : std_logic_vector(data_width_g - 1 downto 0); -- Generator output.
  signal aud_bclk_out_r     : std_logic; -- Codec serial bitclock.
  signal aud_data_out_r     : std_logic; -- Codec serial data output.
  signal aud_lrclk_out_r    : std_logic; -- Codec serial L/R data output.
  signal l_data_codec_tb    : std_logic_vector(data_width_g - 1 downto 0); -- Model output.
  signal r_data_codec_tb    : std_logic_vector(data_width_g - 1 downto 0); -- Model output.
  
  constant fs_c             : integer := (((ref_clk_freq_g / sample_rate_g) / data_width_g) / 4);
  constant bc_time          : integer := fs_c  * 2 * (data_width_g * 2) - 1;
  signal l_data_expected_r  : std_logic_vector(data_width_g - 1 downto 0); -- Expected output from model.
  signal r_data_expected_r  : std_logic_vector(data_width_g - 1 downto 0); -- Expected output from model.
  signal bitcounter_r       : integer; -- Bitcounter for codec output analysis.
  
  signal checkdelay_r       : integer; -- Delay counter to check the sync input effect.
  constant cdelay           : integer  := 1; -- Delay time for previous in main clock cycles.
  
begin -- testbench

  -- Instances
  i_acontrol : audio_ctrl
    generic map(
      data_width_g => data_width_g
    )
    port map(
      rst_n => rst_n,
      clk => clk,
      aud_data_out  => aud_data_out_r,
      aud_bclk_out  => aud_bclk_out_r,
      aud_lrclk_out => aud_lrclk_out_r,
      left_data_in => l_data_wg_actrl,
      right_data_in => r_data_wg_actrl    
    );
    
  i_amodel : audio_codec_model 
    generic map(
      data_width_g => data_width_g
    )
    port map(
      rst_n => rst_n,
      aud_data_in => aud_data_out_r,
      aud_bclk_in => aud_bclk_out_r,
      aud_lrclk_in => aud_lrclk_out_r,
      value_left_out => l_data_codec_tb ,
      value_right_out => r_data_codec_tb 
    );
  
  i_wavegen_left : wave_gen
    generic map(
      width_g => data_width_g,
      step_g => step_w_l_g
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      sync_clear_in => sync_r,
      value_out => l_data_wg_actrl
    ); 
    
  i_wavegen_right : wave_gen
    generic map(
      width_g => data_width_g,
      step_g => step_w_r_g
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      sync_clear_in => sync_r,
      value_out => r_data_wg_actrl
    ); 
    
  -- Clock, reset and sync generation.
  clk <= not clk after clockrate_ns_c/2; -- Create clock pulse.
  rst_n <= '1' after clockrate_ns_c * 4; -- Reset high after 4 pulses.
  sync_r <= not sync_r after 500 us;     -- Note: I wish testbenches had a pseudo random number generator..
  
  -- Check generator sync behavior.
  check_generators : process(clk, rst_n)
  begin
    if(rst_n = '0') then
      -- Reset registers ..
    elsif(clk'event and clk = '1') then
      if(sync_r = '1') then -- If sync is 1 we should have no output after 1 cycle.
        if(checkdelay_r = cdelay) then
          assert (signed(l_data_wg_actrl) = 0) report "Wave gen active on sync = 1" severity failure;
          assert (signed(r_data_wg_actrl) = 0) report "Wave gen active on sync = 1" severity failure;
        else
          checkdelay_r <= checkdelay_r + 1;
        end if;
      else
        checkdelay_r <= 0;
      end if;
    end if;
  end process check_generators;
  
  -- Check codec output from model.
  data_checker : process(clk, rst_n)
  begin
    if(rst_n = '0') then
      --Reset registers ..
      l_data_expected_r <= (others => '0');
      r_data_expected_r <= (others => '0');
      bitcounter_r <= bc_time;
    elsif(clk'event and clk = '1') then
      if(bitcounter_r = bc_time) then -- Store a snapshot locally when the codecs start.
        l_data_expected_r <= l_data_wg_actrl;
        r_data_expected_r <= r_data_wg_actrl;
        bitcounter_r <= bitcounter_r - 1;
      elsif(bitcounter_r = 0) then -- When we reach zero check the output ..
       	if(sync_r = '1') then -- .. assuming we have output .. 
       	  assert (l_data_expected_r = l_data_codec_tb) report "Mismatch in left input/output data" severity failure;
          assert (r_data_expected_r = r_data_codec_tb) report "Mismatch in right input/output data" severity failure;
        end if;
       	bitcounter_r <= bc_time; -- .. and reset the counter to keep it in sync with the codec ..
   	  else
        bitcounter_r <= bitcounter_r - 1; -- Inrement counter (see previous explanation).
      end if;    
    end if;
    end process data_checker;
    
end testbench;