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

entity wave_gen is
  
  generic (
    width_g             : integer;
    step_g              : integer
);
 
 port(
   clk                  : in std_logic;
   rst_n                : in std_logic;
   sync_clear_in        : in std_logic;
   value_out            : out std_logic_vector(width_g - 1 downto 0)  
 );
 
end wave_gen;

architecture rtl of wave_gen is
  type dir_type is (up, down);
  constant maxval_c      : integer := (2**(width_g - 1) - 1)/step_g * step_g;
  constant minval_c     : integer := -maxval_c;
  
  signal dir_r          : dir_type;
  signal count_r        : signed(width_g - 1 downto 0);
  
begin -- rtl
  value_out <= std_logic_vector(count_r);
  
  count : process (clk, rst_n)
  begin
    if(rst_n = '0') then
      count_r <= (others => '0');
    elsif(clk'event and clk = '1') then
      if(sync_clear_in = '1') then
        count_r <= (others => '0');
      else
        case (dir_r) is
          when up =>
            count_r <= count_r + step_g;
          when down =>
            count_r <= count_r - step_g;
        end case;
      end if;
    end if;
  end process count;
  
  compare : process (clk, rst_n)
  begin
    if(rst_n = '0') then
      dir_r <= up;
    elsif(clk'event and clk = '1') then
      if(sync_clear_in = '1') then
        dir_r <= up;
      else
        if(count_r + step_g = maxval_c) then
          dir_r <= down;
        elsif(count_r - step_g = minval_c) then
          dir_r <= up;
        end if;
      end if;
    end if;
  end process compare;
  
end rtl;