-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 02
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : Tuomas Huuki
-- Company    : TUT
-- Created    : 4.11.2015
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Third excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 4.11.2015  1.0      tuhu    Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
  generic(
    operand_width_g : integer
  );
    
  port(
    clk, rst_n : in std_logic;
    a_in : in std_logic_vector(operand_width_g - 1 downto 0);
    b_in : in std_logic_vector(operand_width_g - 1 downto 0);
    sum_out : out std_logic_vector(operand_width_g downto 0)
  );
    
end adder;

architecture rtl of adder is
  
  SIGNAL result : signed((operand_width_g) downto 0); -- Result register.
  
begin -- rtl
  sum_out <= std_logic_vector(result); -- Assign register to output.
  
  -- Handle the actual calculation of values.
  CALCPROC : process (clk, rst_n)
  begin
    if(rst_n = '0') then -- Reset
      result <= (others => '0');
    elsif(clk'event and clk = '1') then -- Calculate on rising edge of clock.
      result <= resize(signed(a_in), operand_width_g + 1) + resize(signed(b_in), operand_width_g + 1);
    end if;
  end process CALCPROC;

end rtl;