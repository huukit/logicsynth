-------------------------------------------------------------------------------
-- Title      : TIE-50206, Exercise 13
-- Project    :
-------------------------------------------------------------------------------
-- File       : tb_i2c_config.vhd
-- Author     : Jonas Nikula, Tuomas Huuki
-- Company    : TUT
-- Created    : 23.1.2016
-- Platform   :
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: I2C bus controller test bench
-------------------------------------------------------------------------------
-- Copyright (c) 2016
-------------------------------------------------------------------------------
-- Revisions  :
-- Date             Version     Author          Description
-- 23.01.2016       1.0         nikulaj         Created
-- 08.02.2016       1.1         nikulaj         Move data to pkg
-- 04.03.2016       1.2         nikulaj         Fix bit checking
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


-------------------------------------------------------------------------------
-- Empty entity
-------------------------------------------------------------------------------

entity tb_i2c_config is
end tb_i2c_config;

-------------------------------------------------------------------------------
-- Architecture
-------------------------------------------------------------------------------
architecture testbench of tb_i2c_config is

  -- Number of parameters to expect
  constant n_params_c     : integer := 10;
  constant i2c_freq_c     : integer := 20000;
  constant ref_freq_c     : integer := 50000000;
  constant clock_period_c : time    := 20 ns;

  -- Every transmission consists several bytes and every byte contains given
  -- amount of bits. 
  constant n_bytes_c       : integer := 3;
  constant bit_count_max_c : integer := 8;

  -- Expected data
  type temp_transmission_arr is array (2 downto 0) of std_logic_vector(7 downto 0);
  signal temp_transmission_r      : temp_transmission_arr;
  constant codec_address_c        : std_logic_vector(7 downto 0) := "00110100";
  signal expected_bit_r     : std_logic;
  type transmission_data_arr is array (n_params_c - 1 downto 0) of std_logic_vector(15 downto 0);
  -- Actual transmission data array.
  constant transmission_data_c    : transmission_data_arr := (
                                                            "0001001000000001",
                                                            "0001000000000010",
                                                            "0000111000000001",
                                                            "0000110000000000",
                                                            "0000101000000110",
                                                            "0000100011111000",
                                                            "0000011001111011",
                                                            "0000010001111011",
                                                            "0000001000011010",
                                                            "0000000000011010"
                                                            );


  constant max_wait_clks_c  : integer := 10;        -- max clk count that sending 
  signal clk_counter_r      : integer;              -- a stop cond should take

  -- places in the transmission where a nack should be sent
  type nack_places_arr is array (n_params_c - 1 downto 0) of std_logic_vector(2 downto 0);
  signal nack_places_r    : nack_places_arr :=    (
                                                      "100",
                                                      "000",
                                                      "010",
                                                      "000",
                                                      "001",
                                                      "000",
                                                      "010",
                                                      "000",
                                                      "001",
                                                      "100"
                                                    );
  signal nack_sent_r        : std_logic;

  -- Signals fed to the DUV
  signal clk   : std_logic := '0';      -- Remember that default values supported
  signal rst_n : std_logic := '0';      -- only in synthesis

  -- The DUV prototype
  component i2c_config
    generic (
      ref_clk_freq_g : integer;
      i2c_freq_g     : integer;
      n_params_g     : integer);
    port (
      clk              : in    std_logic;
      rst_n            : in    std_logic;
      sdat_inout       : inout std_logic;
      sclk_out         : out   std_logic;
      param_status_out : out   std_logic_vector(n_params_g-1 downto 0);
      finished_out     : out   std_logic
      );
  end component;

  -- Signals coming from the DUV
  signal sdat         : std_logic := 'Z';
  signal sclk         : std_logic;
  signal param_status : std_logic_vector(n_params_c-1 downto 0);
  signal finished     : std_logic;

  -- To hold the value that will be driven to sdat when sclk is high.
  signal sdat_r : std_logic;

  -- Counters for receiving bits and bytes
  signal bit_counter_r      : integer range 0 to bit_count_max_c;
  signal byte_counter_r     : integer range 0 to n_bytes_c-1;
  signal status_counter_r   : integer range 0 to n_params_c-1;

  -- States for the FSM
  type   states is (wait_start, read_byte, send_ack, wait_stop);
  signal curr_state_r : states;

  -- Previous values of the I2C signals for edge detection
  signal sdat_old_r : std_logic;
  signal sclk_old_r : std_logic;
  
begin  -- testbench

  clk   <= not clk after clock_period_c/2;
  rst_n <= '1'     after clock_period_c*4;

  -- Assign sdat_r when sclk is active, otherwise 'Z'.
  -- Note that sdat_r is usually 'Z'
  with sclk select
    sdat <=
    sdat_r when '1',
    'Z'    when others;


  -- Component instantiation
  i2c_config_1 : i2c_config
    generic map (
      ref_clk_freq_g => ref_freq_c,
      i2c_freq_g     => i2c_freq_c,
      n_params_g     => n_params_c)
    port map (
      clk              => clk,
      rst_n            => rst_n,
      sdat_inout       => sdat,
      sclk_out         => sclk,
      param_status_out => param_status,
      finished_out     => finished);

  -----------------------------------------------------------------------------
  -- The main process that controls the behavior of the test bench
  fsm_proc : process (clk, rst_n)
  begin  -- process fsm_proc
    if rst_n = '0' then                 -- asynchronous reset (active low)

      curr_state_r <= wait_start;

      sdat_old_r <= '0';
      sclk_old_r <= '0';

      byte_counter_r <= 0;
      bit_counter_r  <= 0;
      clk_counter_r <= 0;

      sdat_r <= 'Z';

      nack_sent_r <= '0';
      
    elsif clk'event and clk = '1' then  -- rising clock edge

      -- The previous values are required for the edge detection
      sclk_old_r <= sclk;
      sdat_old_r <= sdat;


      -- Falling edge detection for acknowledge control
      -- Must be done on the falling edge in order to be stable during
      -- the high period of sclk
      if sclk = '0' and sclk_old_r = '1' then

        -- If we are supposed to send ack
        if curr_state_r = send_ack then

          if(nack_places_r(status_counter_r)(byte_counter_r) = '1' and nack_sent_r = '0') then
            sdat_r <= '1';
            nack_sent_r <= '1';
          -- if it's time to send a nack, send it
          else
          -- Send ack (low = ACK, high = NACK)
            sdat_r <= '0';
          end if;

        else

          -- Otherwise, sdat is in high impedance state.
          sdat_r <= 'Z';

        end if;

      end if;

      if(curr_state_r /= read_byte) then
        expected_bit_r <= 'X';
      end if;
      
      if sclk = '1' and sclk_old_r = '1' and    -- Sdat changed unexpectantly
      sdat_old_r /= sdat then                   -- when clk high
        assert curr_state_r /= read_byte report 
        "Sdat change while clk high and not expecting condition!" severity failure;
      end if;

      -------------------------------------------------------------------------
      -- FSM
      case curr_state_r is

        -----------------------------------------------------------------------
        -- Wait for the start condition
        when wait_start =>

          temp_transmission_r(0) <= codec_address_c;
          temp_transmission_r(1) <= transmission_data_c(status_counter_r)(15 downto 8);
          temp_transmission_r(2) <= transmission_data_c(status_counter_r)(7 downto 0);

          assert clk_counter_r /= max_wait_clks_c report
          "Start signal taking too long" severity failure;

          -- While clk stays high, the sdat falls
          if sclk = '1' and sclk_old_r = '1' and
          sdat_old_r = '1' and sdat = '0' then

            curr_state_r <= read_byte;
            clk_counter_r <= 0;

          elsif sclk = '1' and sclk_old_r = '0' then
            clk_counter_r <= clk_counter_r + 1;  -- if no start cond detected,
                                                 -- increment counter

          end if;

        --------------------------------------------------------------------
        -- Wait for a byte to be read
        when read_byte =>

          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then

            if bit_counter_r /= bit_count_max_c then

              -- Normally just receive a bit
              bit_counter_r <= bit_counter_r + 1;

              expected_bit_r <= temp_transmission_r(byte_counter_r)(7 - bit_counter_r);
              assert (temp_transmission_r(byte_counter_r)(7 - bit_counter_r) = sdat) report
              "Wrong bit!" severity failure;

            else

              -- When terminal count is reached, let's send the ack
              curr_state_r  <= send_ack;
              bit_counter_r <= 0;

            end if;  -- Bit counter terminal count

          end if;  -- sclk rising clock edge

        --------------------------------------------------------------------
        -- Send acknowledge
        when send_ack =>

          -- Detect a rising edge
          if sclk = '1' and sclk_old_r = '0' then

            if(nack_sent_r = '1') then      -- nack was sent, so restart transmission
              byte_counter_r <= 0;
              curr_state_r <= wait_start;
              nack_sent_r <= '0';
              nack_places_r(status_counter_r)(byte_counter_r) <= '0';

            elsif byte_counter_r /= n_bytes_c-1 then

              -- Transmission continues
              byte_counter_r <= byte_counter_r + 1;
              curr_state_r   <= read_byte;

            else

              -- Transmission is about to stop
              byte_counter_r <= 0;
              curr_state_r   <= wait_stop;

            end if;

          end if;

        ---------------------------------------------------------------------
        -- Wait for the stop condition
        when wait_stop =>

          assert clk_counter_r /= max_wait_clks_c report
          "Stop signal taking too long" severity failure;

          -- Stop condition detection: sdat rises while sclk stays high
          if sclk = '1' and sclk_old_r = '1' and
          sdat_old_r = '0' and sdat = '1' then

            curr_state_r <= wait_start;
            status_counter_r <= status_counter_r + 1;
            clk_counter_r <= 0;

          elsif sclk = '1' and sclk_old_r = '0' then
            clk_counter_r <= clk_counter_r + 1;   -- if no start cond detected,
          end if;                                 -- increment counter

      end case;

    end if;
  end process fsm_proc;

  -----------------------------------------------------------------------------
  -- Asserts for verification
  -----------------------------------------------------------------------------

  -- SDAT should never contain X:s.
  assert sdat /= 'X' report "Three state bus in state X" severity error;

  -- End of simulation, but not during the reset
  assert finished = '0' or rst_n = '0' report
  "Simulation done" severity failure;

end testbench;
