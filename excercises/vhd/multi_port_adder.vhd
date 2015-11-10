-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 04
-- Project    : 
-------------------------------------------------------------------------------
-- File       : multi_port_adder.vhd
-- Author     : Tuomas Huuki
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
-- Date        Version  Author  Description
-- 09.11.2015  1.0      tuhu    Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
  
entity multi_port_adder is -- Multi port adder definition.
  generic(
    operand_width_g : integer := 16; -- Specify default value for both.
    num_of_operands_g : integer := 4
  );
  port(
    clk         : in std_logic; -- Clock signal.
    rst_n       : in std_logic; -- Reset, active low.
    operands_in : in std_logic_vector((operand_width_g * num_of_operands_g) - 1 downto 0); -- Operand inputs
    sum_out     : out std_logic_vector(operand_width_g - 1 downto 0) -- Calculation result.
  );
end multi_port_adder;

architecture structural of multi_port_adder is -- Structural declaration utilizing the adder component.
  
  component adder -- Declare component.
    generic(
      operand_width_g : integer 
    );                          
    port( -- See component for definitions of signals.
      clk     : in std_logic;                               
      rst_n   : in std_logic;                                     
      a_in    : in std_logic_vector(operand_width_g - 1 downto 0); 
      b_in    : in std_logic_vector(operand_width_g - 1 downto 0); 
      sum_out : out std_logic_vector(operand_width_g downto 0) 
    );
  end component;
  
  type subtotal_arr is array (0 to (num_of_operands_g / 2) - 1) -- Declare new type for intermediate
    of std_logic_vector(operand_width_g downto 0);              -- result storage.
    
  signal subtotal_r : subtotal_arr; -- Subtotals.
  signal total_r    : std_logic_vector(operand_width_g + 1 downto 0); -- Total addition.
  
begin -- structural
  
  i_adder_1 : adder -- Adder instance 1
    generic map(
      operand_width_g => operand_width_g
    )
    port map(
      clk     => clk,
      rst_n   => rst_n,
      a_in    => operands_in((operand_width_g - 1) downto 0),
      b_in    => operands_in((operand_width_g * 2 - 1) downto operand_width_g),
      sum_out => subtotal_r(0)
    );
    
  i_adder_2 : adder -- Adder instance 2
    generic map(
      operand_width_g => operand_width_g
    )
    port map(
      clk     => clk,
      rst_n   => rst_n,
      a_in    => operands_in((operand_width_g * 3 - 1) downto operand_width_g * 2),
      b_in    => operands_in((operand_width_g * 4 - 1) downto operand_width_g * 3),
      sum_out => subtotal_r(1)
    ); 
    
  i_adder_3 : adder -- Adder instance 3
    generic map(
      operand_width_g => (operand_width_g + 1)
    )
    port map(
      clk     => clk,
      rst_n   => rst_n,
      a_in    => subtotal_r(0),
      b_in    => subtotal_r(1),
      sum_out => total_r
    ); 
    
    sum_out <= total_r((operand_width_g - 1) downto 0); -- Assign total register to output, discarding msb.
    
    assert (num_of_operands_g = 4) report -- Make sure the number of operands is 4.
      "failure: num_of_operands_g is not 4" severity failure;
      
end structural;
