-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 03
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : Tuomas Huuki, Jonas Nikula
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
-- Date        Version  Author      Description
-- 4.11.2015   1.0      tuhu        Created
-- 18.11.2015  1.1      tuhu        Modified process.
-- 20.11.2015  1.1      nikulaj     Added bonus feature
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is
  generic(
    operand_width_g : integer -- Width of input and output. Note, that if the definition of the input width
                          -- is i.e 8, the definition below must be (8 - 1) because the vector starts from 0. 
  );
    
  port(
    clk     : in std_logic;                                         -- Clock signal.
    rst_n   : in std_logic;                                         -- Reset, active low.
    a_in    : in std_logic_vector(operand_width_g - 1 downto 0);    -- Input a.
    b_in    : in std_logic_vector(operand_width_g - 1 downto 0);    -- Input b.
    sum_out : out std_logic_vector(operand_width_g downto 0)        -- Sum output.
  );
    
end adder;

architecture rtl of adder is
  
  SIGNAL result_r : signed((operand_width_g) downto 0); -- Result register.

begin -- rtl
  sum_out <= std_logic_vector(result_r); -- Assign register to output.

  calculate : process (clk, rst_n) -- Handle the actual calculation of values and reset.
  begin
    if(rst_n = '0') then -- Reset
      result_r <= (others => '0');
    elsif(clk'event and clk = '1') then -- Calculate on rising edge of clock.
      result_r <= resize(signed(a_in), operand_width_g + 1) + resize(signed(b_in), operand_width_g + 1);
    end if;
  end process calculate;

end rtl;
