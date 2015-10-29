-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 02
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_ripple_carry_adder.vhd
-- Author     : Tuomas Huuki
-- Company    : TUT
-- Created    : 28.10.2015
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Third excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 28.10.2015  1.0      tuhu    Created
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
    a_in, b_in : in std_logic_vector(operand_width_g - 1 downto 0);
    sum_out : out std_logic_vector(operand_width_g downto 0)
  );
    
end adder;

architecture rtl of adder is
  
  SIGNAL result : signed((operand_width_g) downto 0);
  SIGNAL a_tmp_in : signed((operand_width_g) downto 0);
  SIGNAL b_tmp_in : signed((operand_width_g) downto 0);
  
begin -- rtl
  sum_out <= std_logic_vector(result);
  a_tmp_in <= resize(signed(a_in), operand_width_g + 1);
  b_tmp_in <= resize(signed(b_in), operand_width_g + 1);
  
  -- Handle the actual calculation of values.
  CALCPROC : process (clk, rst_n)
  begin
    if(rst_n = '0') then
      result <= (others => '0');
    end if;
    
    if(clk = '1' and rst_n = '1') then
      result <= a_tmp_in + b_tmp_in;
    end if;
    
  end process CALCPROC;

end rtl;