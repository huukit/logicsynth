-------------------------------------------------------------------------------
-- Title      : TIE-50206, Bonus 5
-- Project    :
-------------------------------------------------------------------------------
-- File       : piano.vhd
-- Author     : Jonas Nikula, Tuomas Huuki
-- Company    : TUT
-- Created    : 10.2.2016
-- Platform   :
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Pieno synth player (sequencer actually).
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date             Version     Author          Description
-- 10.02.2016       1.0         huukit          Created from synthesizer.vhd.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity piano is       -- synthesizer generics and ports
    -- generics
    generic(
        clk_freq_g      : integer := 18432000;
        melody_clk_div  : integer := 18432000 / 2; -- Speed of melody.
        sample_rate_g   : integer := 48000;
        data_width_g    : integer := 16;
        n_keys_g        : integer := 4
    );
    -- ports
    port(
        clk               : in std_logic;
        rst_n             : in std_logic;
        keys_in           : in std_logic_vector(n_keys_g - 1 downto 0);
        melody_in         : in std_logic;
        aud_bclk_out      : out std_logic;
        aud_data_out      : out std_logic;
        aud_lrclk_out     : out std_logic
    );
end piano;

architecture rtl of piano is      -- Defining used signals and components
    component wave_gen is
        generic(
            width_g             : integer; -- Width of the generated wave in bits.
            step_g              : integer  -- Width of one step.
        );
        port(
            clk                 : in std_logic; -- Clock signal.
            rst_n               : in std_logic; -- Reset, actove low.
            sync_clear_in       : in std_logic; -- Sync bit input to clear the counter.
            value_out           : out std_logic_vector(width_g - 1 downto 0)  -- Counter value out.
        );
    end component;

    component multi_port_adder is
        generic(
            operand_width_g     : integer := 16; -- Specify default value for both.
            num_of_operands_g   : integer := 4
        );
        port(
            clk             : in std_logic; -- Clock signal.
            rst_n           : in std_logic; -- Reset, active low.
            operands_in     : in std_logic_vector((operand_width_g * num_of_operands_g) - 1 downto 0); -- Operand inputs
            sum_out         : out std_logic_vector(operand_width_g - 1 downto 0) -- Calculation result.
        );
    end component;

    component audio_ctrl is
        generic(
            ref_clk_freq_g  : integer := 18432000;  -- Reference clock.
            sample_rate_g   : integer := 48000;     -- Sample clock fs.
            data_width_g    : integer := 16         -- Data width.
        );
        port(
            clk             : in std_logic;         -- Main clock.
            rst_n           : in std_logic;         -- Reset, active low.
            left_data_in    : in std_logic_vector(data_width_g - 1 downto 0); -- Data in, left.
            right_data_in   : in std_logic_vector(data_width_g - 1 downto 0); -- Data in, right.
            aud_bclk_out    : out std_logic;        -- Audio bitclock.
            aud_data_out    : out std_logic;        -- Audio data.
            aud_lrclk_out   : out std_logic         -- Audio bitclock L/R select.
        );
    end component;

    type wavegen_output_arr is array (0 to n_keys_g - 1)    -- Define an array type to hold
    of std_logic_vector(data_width_g - 1 downto 0);         -- wavegen output values,
                                                            -- so they can be easily modified
    
    constant melody_len_c : integer := 32;                  -- Define the array and length to hold the                                      
    type melody_arr is array (0 to melody_len_c - 1)        -- melody that is supposed to play.
    of std_logic_vector(n_keys_g -1 downto 0);
  
    constant melody_data_c : melody_arr :=( "1110",         -- Melody data, not very musical. :)
                                            "1101",
                                            "1011",
                                            "0111",
                                            "1011",
                                            "1101",
                                            "1110",
                                            "1100",
                                            "1001",
                                            "0011",
                                            "1001",
                                            "1100",
                                            "1010",
                                            "0101",
                                            "0111",
                                            "1101",
                                            "1011",
                                            "1110",
                                            "0111",
                                            "1011",
                                            "1101",
                                            "1110",
                                            "1110",
                                            "1101",
                                            "1011",
                                            "0111",
                                            "0000",
                                            "1111",
                                            "1001",
                                            "1111",
                                            "0110",
                                            "1111");
    
    -- registers
    signal wavegen_output_r : wavegen_output_arr;
    signal adder_input_r    : std_logic_vector((data_width_g * n_keys_g) - 1 downto 0);
    signal adder_output_r   : std_logic_vector(data_width_g - 1 downto 0);

    signal aud_bclk_r       : std_logic;
    signal aud_data_r       : std_logic;
    signal aud_lrclk_r      : std_logic;

    signal keys_input_r     : std_logic_vector(n_keys_g - 1 downto 0);
    signal melody_counter_r  : integer;

    signal melody_clkcnt_r : integer;
    constant melody_clkdiv_c : integer := melody_clk_div;     
    
begin -- rtl
      -- registers to outputs
    aud_bclk_out <= aud_bclk_r;
    aud_data_out <= aud_data_r;
    aud_lrclk_out <= aud_lrclk_r;
    
    -- Melody player. Reads keys, or plays the melody.
    melody_play : process(clk, rst_n)
    begin
      if(rst_n = '0') then -- Reset outputs.
      
        melody_clkcnt_r <= melody_clkdiv_c;
        melody_counter_r <= 0;
        keys_input_r <= (others => '1');
      
      elsif(clk'event and clk = '1') then
      
        if(melody_in = '0') then -- If no melody requested, use keys.
          keys_input_r <= keys_in;
          melody_counter_r <= 0;
          
        else -- Else step through sequencer pattern.
          keys_input_r <= melody_data_c(melody_counter_r);
          if(melody_clkcnt_r = 0) then
            melody_clkcnt_r <= melody_clkdiv_c;
            melody_counter_r <= melody_counter_r + 1;
            if(melody_counter_r = (melody_len_c - 1)) then
              melody_counter_r <= 0;
            end if;
          else  
            melody_clkcnt_r <= melody_clkcnt_r - 1;
          end if;
        end if;
      end if;
    end process melody_play;
    
    -- a process that scales wavegen output according to how many wavegenerators
    -- are online. If 1 is on, output is divided by 1, 2 = 2, and so on.
    -- This prevents overflow that comes from adding two signals together.
    waveform_scaling : process(clk, rst_n)
        -- process variables
        variable temp : integer := 0;
        variable divider : integer := 0;
    begin
        -- Only process on clock rising edge, and when NOT in reset mode
        if(clk'event and clk = '1' and rst_n = '1') then -- Calculate on rising edge of clock.
            divider := 0;
            for I in 0 to n_keys_g - 1 loop     -- calculate how many buttons are pushed
                if (keys_input_r(I) = '0') then
                    divider := divider + 1;
                end if;
            end loop;
            if (divider = 0) then       -- failsafe to prevent div-by-0
                divider := 1;
            end if;
            for I in 0 to n_keys_g - 1 loop     -- modify wavegen outputs
                temp := to_integer(signed(wavegen_output_r(I)));
                temp := temp / divider;
                adder_input_r((I+1)*data_width_g - 1 downto I*data_width_g) <= std_logic_vector(to_signed(temp, wavegen_output_r(I)'length));
            end loop;
        end if;
    end process waveform_scaling;

    -- instantiate as many wave generators as needed
    wave_generators:
    for I in 0 to n_keys_g - 1 generate
        wavegen_arr : wave_gen
        generic map
        (
            width_g => data_width_g,
            step_g => 2**I
        )
        port map
        (
            clk => clk,
            rst_n => rst_n,
            sync_clear_in => keys_input_r(I),
            value_out => wavegen_output_r(I)
        );
    end generate wave_generators;

    i_adder : multi_port_adder
    generic map
    (
        operand_width_g => data_width_g,
        num_of_operands_g => n_keys_g
    )
    port map
    (
        clk => clk,
        rst_n => rst_n,
        operands_in => adder_input_r,
        sum_out => adder_output_r
    );

    i_audio_ctrl : audio_ctrl
    generic map
    (
        ref_clk_freq_g => clk_freq_g,
        sample_rate_g => sample_rate_g,
        data_width_g => data_width_g
    )
    port map
    (
        clk => clk,
        rst_n => rst_n,
        left_data_in => adder_output_r,
        right_data_in => adder_output_r,
        aud_bclk_out => aud_bclk_r,
        aud_data_out => aud_data_r,
        aud_lrclk_out => aud_lrclk_r
    );

end rtl;
