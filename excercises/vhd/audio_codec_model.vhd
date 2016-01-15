-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 09
-- Project    :
-------------------------------------------------------------------------------
-- File       : audio_codec_model.vhd
-- Author     : Tuomas Huuki
-- Company    : TUT
-- Created    : 14.1.2016
-- Platform   :
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Ninth excercise.
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 14.1.2016   1.0      tuhu    Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Define the entity.
entity audio_codec_model is
  generic(
    data_width_g    : integer :=16
  );
  port(
    rst_n           : in std_logic;
    aud_data_in     : in std_logic;
    aud_bclk_in     : in std_logic;
    aud_lrclk_in    : in std_logic;
    
    value_left_out  : out std_logic_vector(data_width_g - 1 downto 0);
    value_right_out : out std_logic_vector(data_width_g - 1 downto 0)
  );
end audio_codec_model;
  
architecture rtl of audio_codec_model is
  
  -- State definitions for internal codec.
  type state_type is (wait_for_input, read_left, read_right);
  signal present_state_r  : state_type;

  signal bit_counter_r    : integer; -- Number of bits to count per sample.
  signal input_buffer_r   : std_logic_vector(data_width_g - 1 downto 0); -- Input buffer for incoming bits.
  signal input_buffer_l_r : std_logic_vector(data_width_g - 1 downto 0); -- Input buffer for left channel.
  signal input_buffer_r_r : std_logic_vector(data_width_g - 1 downto 0); -- Input buffer for right channel.
  
  begin --rtl
   
  -- Assing output registers to outputs.
  value_left_out <= input_buffer_l_r; 
  value_right_out <= input_buffer_r_r;
  
  handle_input : process (aud_bclk_in, rst_n)
    begin
      if(rst_n = '0') then -- Reset state and output registers.
        present_state_r <= wait_for_input;
        bit_counter_r <= (data_width_g - 1);
        input_buffer_l_r <= (others => '0');
        input_buffer_r_r <= (others => '0');
        
      elsif(aud_bclk_in'event and aud_bclk_in = '1') then -- Read input on bclk rising edge.
        
        case present_state_r is -- Handle init and other states.
          
          when wait_for_input => -- First input data, look for direction.
            input_buffer_r(bit_counter_r) <= aud_data_in;
            if(aud_lrclk_in = '0') then
              present_state_r <= read_right;
            else
              present_state_r <= read_left;
            end if;
            bit_counter_r <= bit_counter_r - 1; 
            
          when read_right => -- Read right channel data.
            if(bit_counter_r = 0) then -- Reset counter and change channel if we have all data.
              input_buffer_r_r(bit_counter_r) <= aud_data_in;
              input_buffer_r_r(data_width_g - 1 downto 1) <= input_buffer_r(data_width_g - 1 downto 1);
              -- Note: Is the above line ok? Same for the left channel.
              bit_counter_r <= (data_width_g - 1);
              present_state_r <= read_left;
            else
              input_buffer_r(bit_counter_r) <= aud_data_in;
              bit_counter_r <= bit_counter_r - 1; 
            end if;
                         
          when read_left => -- Read left channel data.
            if(bit_counter_r = 0) then -- Reset counter and change channel if we have all data.
              input_buffer_l_r(bit_counter_r) <= aud_data_in;
              input_buffer_l_r(data_width_g - 1 downto 1) <= input_buffer_r(data_width_g - 1 downto 1);
              bit_counter_r <= (data_width_g - 1);
              present_state_r <= read_right; 
            else
              input_buffer_r(bit_counter_r) <= aud_data_in;
              bit_counter_r <= bit_counter_r - 1;             
            end if;

        end case;
        
      end if;      
    end process handle_input;
  
end rtl;