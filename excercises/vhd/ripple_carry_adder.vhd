-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 02
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ripple_carry_adder.vhd
-- Author     : Jonas Nikula
-- Company    : TUT
-- Created    : 2015-10-30
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Sums two 3-bit values
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------


-- Include default libraries
library ieee;
use ieee.std_logic_1164.all;


-- DONE: Declare entity here
-- Name: ripple_carry_adder
-- No generics yet
-- Ports: a_in  3-bit std_logic_vector
--        b_in  3-bit std_logic_vector
--        s_out 4-bit std_logic_vector
entity ripple_carry_adder is
  port (a_in, b_in: in std_logic_vector(2 downto 0);
       s_out: out std_logic_vector(3 downto 0));
end ripple_carry_adder;



-------------------------------------------------------------------------------

-- Architecture called 'gate' is already defined. Just fill it.
-- Architecture defines an implementation for an entity
architecture gate of ripple_carry_adder is
  -- DONE: Add your internal signal declarations here
  signal Carry_ha, C, D, E, Carry_fa, F, G, H : std_logic;
  -- component gate
  --   port (a, b: in bit;
  --         c: out bit);
  -- end component;
begin  -- gate
  -- DONE: Add signal assignments here
  -- x(0) <= y and z(2);
  -- Remember that VHDL signal assignments happen in parallel
  -- Don't use processes
  s_out(0) <= a_in(0) xor b_in(0);
  Carry_ha <= a_in(0) and b_in(0);

  C <= a_in(1) xor b_in(1);
  E <= a_in(1) and b_in(1);
  D <= C and Carry_ha;
  s_out(1) <= C xor Carry_ha;
  Carry_fa <= D or E;

  F <= a_in(2) xor b_in(2);
  H <= a_in(2) and b_in(2);
  s_out(2) <= F xor Carry_fa;
  G <= F and Carry_fa;
  s_out(3) <= G and H;

end gate;
