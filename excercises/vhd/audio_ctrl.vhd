-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 08
-- Project    :
-------------------------------------------------------------------------------
-- File       : audio_ctrl.vhd
-- Author     : Jonas Nikula, Tuomas Huuki
-- Company    : TUT
-- Created    : 11.1.2016
-- Platform   :
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Controller for Wolfson WM8731 -audio codec
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 11.01.2016   1.0     nikulaj Created
-- 12.01.2016   1.1     huukit  Drafting functionality.
-- 15.01.2016   1.2     huukit  Fixed a bug where the snapshot was incorrectly updated.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Define the entity.
entity audio_ctrl is
  generic(
    ref_clk_freq_g  : integer := 18432000;  -- Reference clock.
    sample_rate_g   : integer := 48000;     -- Sample clock fs.
    data_width_g    : integer := 16         -- Data width.
    );
      
  port(
    clk             : in std_logic;         -- Main clock.
    rst_n           : in std_logic;         -- Reset, active low.
    left_data_in    : in std_logic_vector(data_width_g - 1 downto 0); -- Data in, left.
    right_data_in   : in std_logic_vector(data_width_g - 1 downto 0); -- Data in, right.
    aud_bclk_out    : out std_logic;        -- Audio bitclock.
    aud_data_out    : out std_logic;        -- Audio data.
    aud_lrclk_out   : out std_logic         -- Audio bitclock L/R select.
    );
end audio_ctrl;

architecture rtl of audio_ctrl is
  -- Calculate contants for clock generation counters.
  constant fs_c           : integer := (((ref_clk_freq_g / sample_rate_g) / data_width_g) / 4) - 1;
  constant lr_c           : integer := (data_width_g * 2) - 1;
  
  -- Define the width of the counters used.
  constant clk_c_width_c  : integer := 16;
  
  -- Clock counters.
  signal bclk_count_r     : unsigned(clk_c_width_c - 1 downto 0);
  signal lr_count_r       : unsigned(clk_c_width_c - 1 downto 0);
  
  -- Data and control registers.
  signal left_data_ss_r   : std_logic_vector(data_width_g - 1 downto 0);
  signal right_data_ss_r  : std_logic_vector(data_width_g - 1 downto 0);
  signal aud_data_r       : std_logic;
  signal bclk_r           : std_logic;
  signal lr_r             : std_logic;
  
begin --rtl
    
  -- Assign registers to outputs.
  aud_bclk_out <= bclk_r; 
  aud_lrclk_out <= lr_r;
  aud_data_out <= aud_data_r;
  
  bclock : process (clk, rst_n) -- Generates the bit and lr clocks.
  begin
    if(rst_n = '0') then
      bclk_count_r <= to_unsigned(fs_c, bclk_count_r'length);
      lr_count_r  <= to_unsigned(lr_c, lr_count_r'length);
      bclk_r <= '0';
      lr_r <= '1';
    elsif(clk'event and clk = '1') then
    
      if(bclk_count_r = 0) then -- Handle bclk.
        bclk_r <= not bclk_r; -- bclk Invert on compare.
        bclk_count_r <= to_unsigned(fs_c, bclk_count_r'length); -- bclk  Reset counter.
       
        if(lr_count_r = 0) then -- Handle L/R selection.
          lr_r <= not lr_r; -- L/R invert on compare.
          lr_count_r  <= to_unsigned(lr_c, lr_count_r'length); -- L/R reset counter.
        else
          lr_count_r <= lr_count_r - 1; -- L/R count down.
        end if;
        
      else
        bclk_count_r <= bclk_count_r - 1; -- bclk Count down.
      end if;  
      
    end if;
  end process bclock;
  
  
  dataload : process (clk, rst_n) -- Load and serialize the input data.
  begin
    if(rst_n = '0') then -- Reset clears dataregisters.
      left_data_ss_r <= (others => '0');
      right_data_ss_r <= (others => '0');
      aud_data_r <= '0';
    elsif(clk'event and clk = '1') then
    
      if(lr_count_r = lr_c and  bclk_count_r = fs_c) then -- Store and load.
        aud_data_r <= left_data_in(to_integer(lr_count_r / 2)); -- Load first bit.
        if(lr_r = '1') then -- Only store snapshot on SOF.
          left_data_ss_r <= left_data_in; -- Store snapshots.
          right_data_ss_r <= right_data_in;  
        end if;
      elsif(bclk_r = '0' and bclk_count_r = (fs_c - 1)) then -- Load next bit(s).
      
        if(lr_r = '1') then -- load left data.
          aud_data_r <= left_data_ss_r(to_integer(lr_count_r / 2)); 
        else -- load right.
          aud_data_r <= right_data_ss_r(to_integer(lr_count_r / 2)); 
        end if;
        
      end if;   
    end if;
   end process dataload;
   
end rtl;
  
  