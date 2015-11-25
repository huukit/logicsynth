-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 06
-- Project    : 
-------------------------------------------------------------------------------
-- File       : wave_gen_bonus.vhd
-- Author     : Tuomas Huuki
-- Company    : TUT
-- Created    : 23.11.2015
-- Platform   :
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Sixth excercise (bonus).
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 25.11.2015  1.0      tuhu    Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;
use ieee.fixed_pkg.all;

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

  constant maxval_c     : integer := (2**(width_g - 1) - 1); -- Maximum value for output.
  constant minval_c     : integer := -maxval_c; -- Minimun value for output.
  constant decimals_c   : integer := -32;
  
  constant d_c          : sfixed(width_g downto decimals_c) := resize((2 * to_sfixed(3.145, width_g, decimals_c)) / maxval_c, width_g + 5, decimals_c);
 
  signal count_r        : sfixed(width_g downto decimals_c);
  signal sin_r          : sfixed(width_g downto decimals_c);
  signal cos_r          : sfixed(width_g downto decimals_c);
  signal result_r       : sfixed(width_g downto decimals_c); 
begin -- rtl

  value_out <= std_logic_vector(to_signed(result_r, width_g)); -- Assign register to output.
  --count_r <= (others => '0') when (count_r = maxval_c);
  
  count : process (clk, rst_n) -- Process to increment or decrement counter value.
  begin
    if(rst_n = '0') then 
      count_r <= (others => '0'); -- Clear the output on reset ...
      sin_r <= (others => '0');
      cos_r <= to_sfixed(1.0, cos_r);
    elsif(clk'event and clk = '1') then 
      sin_r <= resize(sin_r + cos_r * d_c, sin_r'high, sin_r'low);
      cos_r <= resize(cos_r - sin_r * d_c, cos_r'high, cos_r'low);
      
      result_r <= resize(sin_r * count_r, result_r'high, result_r'low);
      
      count_r <= resize(count_r + to_sfixed(1.0, count_r), count_r'high, count_r'low);
      if(count_r = maxval_c - 1) then
          count_r <= (others => '0');
          sin_r <= (others => '0');
          cos_r <= to_sfixed(1.0, cos_r);
       end if;
    end if; -- clk'event ...
  end process count;
  
end rtl;
