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
  
entity multi_port_adder is
  generic(
    operand_width_g : integer := 16;
    num_of_operands_g : integer := 4
  );
  port(
    clk         : in std_logic;
    rst_n       : in std_logic;
    operands_in : in std_logic_vector((operand_width_g * num_of_operands_g) - 1 downto 0);
    sum_out     : out std_logic_vector(operand_width_g - 1 downto 0)
  );
end multi_port_adder;

architecture structural of multi_port_adder is
  
  component adder 
    generic(
      operand_width_g : integer 
    );                          
    port(
      clk     : in std_logic;                                   
      rst_n   : in std_logic;                                     
      a_in    : in std_logic_vector(operand_width_g - 1 downto 0); 
      b_in    : in std_logic_vector(operand_width_g - 1 downto 0); 
      sum_out : out std_logic_vector(operand_width_g downto 0) 
    );
  end component;
  
  type subtotal_arr is array (0 to (num_of_operands_g / 2) - 1) of std_logic_vector(operand_width_g downto 0);
  signal subtotal_r : subtotal_arr;
  signal total_r    : std_logic_vector(operand_width_g + 1 downto 0);
  
begin -- structural
  adder_a : adder
    generic map(
      operand_width_g => operand_width_g
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      a_in => operands_in(15 downto 0),
      b_in => operands_in(31 downto 16),
      sum_out => subtotal_r(0)
    );
    
  adder_b : adder
    generic map(
      operand_width_g => operand_width_g
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      a_in => operands_in(47 downto 32),
      b_in => operands_in(63 downto 48),
      sum_out => subtotal_r(1)
    ); 
    
  adder_c : adder
    generic map(
      operand_width_g => (operand_width_g + 1)
    )
    port map(
      clk => clk,
      rst_n => rst_n,
      a_in => subtotal_r(0),
      b_in => subtotal_r(1),
      sum_out => total_r
    ); 
    
    sum_out <= total_r((operand_width_g - 1) downto 0);
    
    assert (num_of_operands_g = 4) report "failure: num_of_operands_g is not 4" severity failure;
end structural;