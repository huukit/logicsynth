-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 06
-- Project    : 
-------------------------------------------------------------------------------
-- File       : wave_gen.vhd
-- Author     : Tuomas Huuki
-- Company    : TUT
-- Created    : 23.11.2015
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Sixth excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 23.11.2015  1.0      tuhu    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity wave_gen is -- Wave generator entity.
  
  generic (
    width_g             : integer; -- Width of the generated wave in bits.
    step_g              : integer -- Width of one step.
  );
  port(
    clk                 : in std_logic; -- Clock signal.
    rst_n               : in std_logic; -- Reset, actove low.
    sync_clear_in       : in std_logic; -- Sync bit input to clear the counter.
    value_out           : out std_logic_vector(width_g - 1 downto 0)  -- Counter value out.
  );
end wave_gen;

architecture rtl of wave_gen is
  
  type dir_type is (up_t, down_t); -- Definition for counter direction type.
    
  constant maxval_c     : integer := (2**(width_g - 1) - 1)/step_g * step_g; -- Maximum value for counter.
  constant minval_c     : integer := -maxval_c; -- Minimun value for counter.
  
  signal dir_r          : dir_type; -- Counter direction.
  signal count_r        : signed(width_g - 1 downto 0); -- Counter count register.
  
begin -- rtl

  value_out <= std_logic_vector(count_r); -- Assign register to output.
  
  dir_r <= down_t when (count_r = maxval_c) -- Detect direction and update.
      else up_t   when (count_r = minval_c)
      else up_t   when (sync_clear_in = '1' or rst_n = '0');  
  
  count : process (clk, rst_n) -- Process to increment or decrement counter value.
  begin
    if(rst_n = '0') then 
      count_r <= (others => '0'); -- Clear the output on reset ...
    elsif(clk'event and clk = '1') then 
      if(sync_clear_in = '1') then
        count_r <= (others => '0'); -- ... or if the sync bit is active.
      else
        case (dir_r) is -- Check the direction and step the counter up or down.
          when up_t =>
            count_r <= count_r + step_g; -- Step counter up.
          when down_t =>
            count_r <= count_r - step_g; -- Step counter down.
        end case; -- dir_r
      end if; -- sync_clear_in
    end if; -- clk'event ...
  end process count;
  
end rtl;