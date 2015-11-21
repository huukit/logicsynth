-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 04
-- Project    : 
-------------------------------------------------------------------------------
-- File       : multi_port_adder.vhd
-- Author     : Tuomas Huuki, Jonas Nikula
-- Company    : TUT
-- Created    : 09.11.2015
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Fourth excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author      Description
-- 09.11.2015  1.0      tuhu        Created
-- 20.11.2015  1.1      nikulaj     Added bonus feature
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity multi_port_adder is -- Multi port adder definition.
  generic
  (
    operand_width_g : integer := 16; -- Specify default value for both.
    num_of_operands_g : integer := 4
  );
  port
  (
    clk         : in std_logic; -- Clock signal.
    rst_n       : in std_logic; -- Reset, active low.
    operands_in : in std_logic_vector((operand_width_g * num_of_operands_g) - 1 downto 0); -- Operand inputs
    sum_out     : out std_logic_vector(operand_width_g - 1 downto 0) -- Calculation result.
  );
end multi_port_adder;

architecture structural of multi_port_adder is -- Structural declaration utilizing the adder component.

  component adder -- Declare component.
    generic
    (
    operand_width_g : integer 
  );                          
  port
  ( -- See component for definitions of signals.
    clk     : in std_logic;                               
    rst_n   : in std_logic;                                     
    a_in    : in std_logic_vector(operand_width_g - 1 downto 0); 
    b_in    : in std_logic_vector(operand_width_g - 1 downto 0); 
    sum_out : out std_logic_vector(operand_width_g downto 0) 
  );
  end component;

  type calculation_values_arr is array (0 to 2*num_of_operands_g - 2) -- Declare new type for all values.
  of std_logic_vector(operand_width_g downto 0);

  signal values_r : calculation_values_arr; -- All calculation values (inputs and outputs).


begin -- structural

  assert ((num_of_operands_g mod 2) = 0) report -- Make sure the number of operands is a factor of 2.
  "failure: num_of_operands_g is not a factor of 2!" severity failure;

  inputs_to_arr: process    -- Move the inputs to the value array.
  begin
    for I in 0 to (num_of_operands_g - 1) loop
      wait until rising_edge(clk);
      values_r(values_r'length - 1 - I)(2 downto 0) <= operands_in((operands_in'length - 1) - I*operand_width_g downto operands_in'length - (I+1)*operand_width_g);
      values_r(values_r'length - 1 - I)(3) <= '0';
    end loop;

  end process inputs_to_arr;

  adders:
  for I in 0 to num_of_operands_g - 1 generate

    i_adder : adder -- Adder instance 1
    generic map
    (
      operand_width_g => operand_width_g
    )
    port map
    (
      clk     => clk,
      rst_n   => rst_n,
      a_in    => values_r(values_r'length - I - 1)(operand_width_g - 1 downto 0),
      b_in    => values_r(values_r'length - I - 2)(operand_width_g - 1 downto 0),
      sum_out => values_r(num_of_operands_g - I)
    );
  end generate adders;

  sum_out <= values_r(0)(operand_width_g - 1 downto 0);


end structural;
