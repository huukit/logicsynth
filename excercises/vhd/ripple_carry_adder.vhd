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
-- Description: Second excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 28.10.2015  1.0      tuhu    Created
-------------------------------------------------------------------------------

-- TODO: Add library called ieee here
--       And use package called std_logic_1164 from the library
library ieee;
use ieee.std_logic_1164.all;

-- TODO: Declare entity here
-- Name: ripple_carry_adder
-- No generics yet
-- Ports: a_in  3-bit std_logic_vector
--        b_in  3-bit std_logic_vector
--        s_out 4-bit std_logic_vector
entity ripple_carry_adder is
  PORT (
    a_in  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    b_in  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
end ripple_carry_adder;

-------------------------------------------------------------------------------

-- Architecture called 'gate' is already defined. Just fill it.
-- Architecture defines an implementation for an entity
architecture gate of ripple_carry_adder is

  -- TODO: Add your internal signal declarations here
  SIGNAL carry_ha : STD_LOGIC;
  SIGNAL carry_fa : STD_LOGIC;
  SIGNAL C, D, E, F, G, H : STD_LOGIC;
  
begin  -- gate
  -- Half adder.
  s_out(0) <= a_in(0) XOR b_in(0);
  carry_ha <= a_in(0) AND b_in(0);

  -- Full adder 1.
  C <= a_in(1) XOR b_in(1);
  D <= carry_ha AND C;
  E <= a_in(1) AND b_in(1);
  s_out(1) <= carry_ha XOR C;
  carry_fa <= D OR E;
  
  -- Full adder 2.  
  F <= a_in(2) XOR b_in(2);
  G <= carry_fa AND F;
  H <= a_in(2) AND b_in(2);
  s_out(2) <= carry_fa XOR F;
  s_out(3) <= G OR H;
  
end gate;
