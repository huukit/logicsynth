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
  
  type state_type is (wait_for_input, read_left, read_right);
  signal present_state_r  : state_type;

  signal bit_counter_r    : integer;
  signal input_buffer_l_r : std_logic_vector(data_width_g - 1 downto 0); 
  signal input_buffer_r_r : std_logic_vector(data_width_g - 1 downto 0); 
  
  begin --rtl
   
  value_left_out <= input_buffer_l_r;
  value_right_out <= input_buffer_r_r;
  
  handle_input : process (aud_bclk_in, rst_n)
    begin
      if(rst_n = '0') then -- Reset state and output registers.
        present_state_r <= wait_for_input;
        bit_counter_r <= (data_width_g - 1);
        input_buffer_r_r <= (others => '0');
        input_buffer_l_r <= (others => '0');
      elsif(aud_bclk_in'event and aud_bclk_in = '1') then -- Read input on bclk rising edge.
        
        case present_state_r is -- Handle init and other states.
          
          when wait_for_input => -- First input data, look for direction.
            if(aud_lrclk_in = '0') then
              input_buffer_r_r(bit_counter_r) <= aud_data_in;
              present_state_r <= read_right;
            else
              input_buffer_l_r(bit_counter_r) <= aud_data_in;
              present_state_r <= read_left;
            end if;
              
          when read_right => -- Read right channel data.
            input_buffer_r_r(bit_counter_r) <= aud_data_in;
            if(bit_counter_r = 0) then -- Reset counter and change channel if we have all data.
              bit_counter_r <= (data_width_g - 1);
              present_state_r <= read_left;
            end if;
                         
          when read_left => -- Read left channel data.
            input_buffer_l_r(bit_counter_r) <= aud_data_in;
            if(bit_counter_r = 0) then -- Reset counter and change channel if we have all data.
              bit_counter_r <= (data_width_g - 1);
              present_state_r <= read_right;              
            end if;

        end case;

      bit_counter_r <= bit_counter_r - 1;  
      end if;      
    end process handle_input;
  
end rtl;