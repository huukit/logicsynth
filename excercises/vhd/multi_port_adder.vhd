-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 04
-- Project    : 
-------------------------------------------------------------------------------
-- File       : multi_port_adder.vhd
-- Author     : Jonas Nikula
-- Company    : TUT
-- Created    : 12.11.2015
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description: Fourth excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author      Description
-- 12.11.2015  1.0      nikulaj     Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;


entity multi_port_adder is
    generic 
    (
        operand_width_g : integer := 16;
        num_of_operands_g : integer := 4
    );

    port
    ( 
        clk : in std_logic;
        rst_n : in std_logic;
        operands_in : in std_logic_vector(operand_width_g * num_of_operands_g - 1 DOWNTO 0);
        sum_out : out std_logic_vector(operand_width_g - 1 DOWNTO 0)
    );
end multi_port_adder;

architecture structural of multi_port_adder is
    component adder
        port
        (
            clk : in std_logic; 
            rst_n : in std_logic; 
            a_in : in std_logic_vector(operand_width_g - 1 DOWNTO 0);
            b_in : in std_logic_vector(operand_width_g - 1 DOWNTO 0);
            sum_out : out std_logic_vector(operand_width_g DOWNTO 0)
        );
    end component;

    type subtotal_type is array (0 TO (num_of_operands_g/2)-1) of
    std_logic_vector(operand_width_g DOWNTO 0);

    signal subtotal_r : subtotal_type;
    signal total_r : std_logic_vector(operand_width_g + 1 DOWNTO 0);

begin
    assert (num_of_operands_g = 4) report "Number of operands isn't 4!" severity failure;

    adder1 : adder
    generic map ( operand_width_g => operand_width_g )
    port map
    (
        clk => clk,
        rst_n => rst_n,
        a_in => operands_in(operand_width_g * 4 - 1 DOWNTO operand_width_g * 3),
        b_in => operands_in(operand_width_g * 3 - 1 DOWNTO operand_width_g * 2),
        sum_out => subtotal_r(1)
    );
    adder2 : adder
    generic map ( operand_width_g => operand_width_g )
    port map
    (
        clk => clk,
        rst_n => rst_n,
        a_in => operands_in(operand_width_g * 2 - 1 DOWNTO operand_width_g * 1),
        b_in => operands_in(operand_width_g * 1 - 1 DOWNTO operand_width_g * 0),
        sum_out => subtotal_r(0)
    );
    final_adder : adder
    generic map ( operand_width_g => operand_width_g + 1)
    port map 
    (
        clk => clk,
        rst_n => rst_n,
        a_in => subtotal_r(1),
        b_in => subtotal_r(0),
        sum_out => total_r
    );

    sum_out <= total_r(operand_width_g - 1 DOWNTO 0);

end structural;
