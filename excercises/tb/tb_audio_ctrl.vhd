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
use ieee.numeric_std.all;

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
  
  constant clockrate_ns_c : time := 50 ns;
  
  signal clk                : std_logic := '0';
  signal rst_n              : std_logic := '0';
  signal sync_r             : std_logic := '0';
  signal l_data_wg_actrl    : std_logic_vector(data_width_g - 1 downto 0);
  signal r_data_wg_actrl    : std_logic_vector(data_width_g - 1 downto 0);
  signal aud_bclk_out_r     : std_logic;
  signal aud_data_out_r     : std_logic;
  signal aud_lrclk_out_r    : std_logic;
  signal l_data_codec_tb    : std_logic_vector(data_width_g - 1 downto 0);
  signal r_data_codec_tb    : std_logic_vector(data_width_g - 1 downto 0);
  
  constant fs_c             : integer := (((ref_clk_freq_g / sample_rate_g) / data_width_g) / 4);
  constant bc_time          : integer := fs_c  * 2 * (data_width_g * 2) - 1;
  signal l_data_expected_r  : std_logic_vector(data_width_g - 1 downto 0);
  signal r_data_expected_r  : std_logic_vector(data_width_g - 1 downto 0);
  signal bitcounter_r       : integer;
  
  signal checkdelay_r       : integer;
  constant cdelay           : integer  := 1;
  
begin -- testbench
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
    
  clk <= not clk after clockrate_ns_c/2; -- Create clock pulse.
  rst_n <= '1' after clockrate_ns_c * 4; -- Reset high after 4 pulses.
  sync_r <= not sync_r after 100 us;
  
  check_generators : process(clk, rst_n)
  begin
    if(rst_n = '0') then
      -- Reset registers ..
    elsif(clk'event and clk = '1') then
      if(sync_r = '1') then -- If sync is 1 and generators are producing output.
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
  
  data_checker : process(clk, rst_n)
  begin
    if(rst_n = '0') then
      --Reset registers ..
      bitcounter_r <= bc_time;
    elsif(clk'event and clk = '1') then
      if(bitcounter_r = bc_time) then
        l_data_expected_r <= l_data_wg_actrl;
        r_data_expected_r <= r_data_wg_actrl;
        bitcounter_r <= bitcounter_r - 1;
      elsif(bitcounter_r = 0) then
       	bitcounter_r <= bc_time;
       	--assert (l_data_expected_r = l_data_codec_tb) report "Mismatch in left input/output data" severity failure;
        --assert (r_data_expected_r = r_data_codec_tb) report "Mismatch in right input/output data" severity failure;
      elsif(sync_r = '1') then
        	bitcounter_r <= bc_time;
   	  else
        bitcounter_r <= bitcounter_r - 1;
      end if;    
    end if;
    end process data_checker;
end testbench;