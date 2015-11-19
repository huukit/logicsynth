-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 05
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_multi_port_adder.vhd
-- Author     : Tuomas Huuki
-- Company    : TUT
-- Created    : 18.11.2015
-- Platform   :
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Fifth excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2015 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 18.11.2015   1.0      tuhu    Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all; -- Will not synthesize.

entity tb_multi_port_adder is
  generic(
    operand_width_g : integer := 3 -- Operand width definition.
    -- operand_width_g : integer := 4 -- Operand width definition (testing generics).
  );
end tb_multi_port_adder;

architecture testbench of tb_multi_port_adder is

  -- Constant definitions.
  constant clockrate_ns_c     : time := 10 ns; -- Clockrate ns.
  constant num_of_operands_c  : integer := 4; -- Number of operands.
  constant duv_output_delay_c : integer := 2; -- The delay of the output in clock cycles.

  -- Signals
  signal clk                  : std_logic := '0'; -- Clock.
  signal rst_n                : std_logic := '0'; -- Reset, active low.
  signal operands_r           : std_logic_vector((operand_width_g * num_of_operands_c) - 1 downto 0);
  signal sum_r                : std_logic_vector(operand_width_g - 1 downto 0);
  signal output_valid_r       : std_logic_vector(duv_output_delay_c downto 0);
  
  -- Needed files for test bench.
  file input_f                : text open read_mode is "input.txt";
  file ref_results_f          : text open read_mode is "ref_results.txt";
  file output_f               : text open write_mode is "output.txt";
  
  -- DUV declaration.
  component multi_port_adder is -- Multi port adder definition.
  generic(
    operand_width_g : integer := 16; -- Specify default value for both.
    num_of_operands_g : integer := 4
  );
  port(
    clk                       : in std_logic; -- Clock signal.
    rst_n                     : in std_logic; -- Reset, active low.
    operands_in               : in std_logic_vector((operand_width_g * num_of_operands_g) - 1 downto 0); -- Operand inputs
    sum_out                   : out std_logic_vector(operand_width_g - 1 downto 0) -- Calculation result.
  );
  end component;

begin --testbench

  -- DUV instance.
  i_adder : multi_port_adder
    generic map(
      operand_width_g => operand_width_g,
      num_of_operands_g => num_of_operands_c
    )
    port map(
      rst_n => rst_n,
      clk => clk,
      operands_in => operands_r,
      sum_out => sum_r      
    );
    
  clk <= not clk after clockrate_ns_c/2; -- Create clock pulse.
  rst_n <= '1' after clockrate_ns_c * 4; -- Reset high after 4 pulses.

  input_reader : process(clk, rst_n) -- Read the input values from a file and feed to DUV.
  
    type integer_arr_t is array (num_of_operands_c - 1 downto 0)
      of integer;
      
    variable inputline_v        : line;
    variable inputs_v           : integer_arr_t;
    
  begin -- input_reader
    
    if rst_n = '0' then
      operands_r <= (others  => '0');
      output_valid_r <= (others => '0');
    elsif clk'event and clk = '1' then
      -- Set lsb = 1 ja shift left.
      output_valid_r <= std_logic_vector(signed(output_valid_r) sll 1); 
      output_valid_r(0) <= '1';
      -- Read the input data in a loop.
      if (not endfile(input_f)) then
        readline(input_f, inputline_v); -- Read line from file.
        for i in 0 to (num_of_operands_c - 1) loop 
          read(inputline_v, inputs_v(i)); -- Then get value from line ...
          operands_r((((i + 1) * operand_width_g) -1) downto (i * operand_width_g)) 
            <= std_logic_vector(to_signed(inputs_v(i), operand_width_g)); -- ... and write it to the register.
        end loop;
     end if;
    end if;
  
  end process input_reader;
  
  checker : process(clk, rst_n) -- Check the adder output and compare it to the read file.
  
    variable resultline_v       : line; -- Line where the result is read from file.
    variable result_v           : integer; -- Result from file.
    variable resultout_v        : line; --  Line to store adder output.
    
  begin -- checker
  
    if rst_n = '0' then
      -- No input registers to reset.
    elsif clk'event and clk = '1' then
      if output_valid_r(duv_output_delay_c) = '1' then -- Check results when msb of output valid is 1
        if (not endfile(ref_results_f)) then
          readline(ref_results_f, resultline_v); -- Read a line from the result file.
          read(resultline_v, result_v); -- Read a result from the result line.
          assert (result_v = to_integer(signed(sum_r))) -- Assert, that the result is equel to the sum.
            report "Adder output is not equal to the reference value!" severity failure;
          write(resultout_v, to_integer(signed(sum_r))); -- Write the sum to the result output line.
          writeline(output_f, resultout_v); -- Finally write the output line to the file.
        else
          assert false 
            report "Simulation done!" severity failure; -- End simulation when all results have been read.
        end if; -- endfile
      end if; -- output valid.
    end if; -- clk
    
  end process checker;
end testbench;