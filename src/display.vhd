-- Copyright (c) 2020 Josh Bassett
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- The display controller continuously refreshes the display data from RAM
-- and converts it into row/column signals.
--
-- The rows are refreshed from top to bottom. The leds in each row are
-- pulse-width modulated.
entity display is
  generic (
    ADDR_WIDTH     : natural := 6;
    DATA_WIDTH     : natural := 8;
    DISPLAY_WIDTH  : natural := 8;
    DISPLAY_HEIGHT : natural := 8
  );
  port (
    -- reset
    reset : in std_logic;

    -- clock
    clk : in std_logic;

    -- memory IO
    ram_addr : out unsigned(ADDR_WIDTH-1 downto 0);
    ram_data : in std_logic_vector(DATA_WIDTH-1 downto 0);

    row_addr : out unsigned(2 downto 0);

    -- matrix IO
    matrix_rows : out std_logic_vector(DISPLAY_HEIGHT-1 downto 0);
    matrix_cols : out std_logic_vector(DISPLAY_WIDTH-1 downto 0)
  );
end display;

architecture arch of display is
  -- The number of clock ticks to wait in the wait state. When loading data
  -- into the shift register, we need to wait for the memory and gamma
  -- correction to finish outputting their data.
  constant WAIT_MAX : natural := 1;

  -- The maximum value of the PWM counter. There are only n-1 duty-cycle values.
  constant PWM_MAX : natural := 254;

  type state_type is (RESET_STATE, LOAD_STATE, ADDR_STATE, WAIT_STATE, LATCH_STATE);
  signal state, next_state : state_type;

  -- Flags
  signal led, load, latch, oe, wait_en, pwm_inc, row_inc, col_inc : std_logic;

  -- Wait counter
  signal wait_ctr : natural range 0 to WAIT_MAX;

  -- Pulse-width modulation counter
  signal pwm_ctr : natural range 0 to PWM_MAX;

  -- Address counter
  signal address_ctr : unsigned(ADDR_WIDTH-1 downto 0);

  -- Gamma-corrected data
  signal gamma_data : unsigned(DATA_WIDTH-1 downto 0);

  -- The shift register which the led values are loaded into.
  signal shift_reg : std_logic_vector(DISPLAY_WIDTH-1 downto 0);

  -- The columns output register.
  signal cols_reg : std_logic_vector(DISPLAY_WIDTH-1 downto 0);

  -- Row address
  signal row_addr_reg : unsigned(2 downto 0);
begin
  -- Apply gamma-correction to the display data.
  gamma_correction : entity work.gamma
    generic map (
      GAMMA      => 1.8,
      DATA_WIDTH => DATA_WIDTH
    )
    port map (
      clk      => clk,
      data_in  => unsigned(ram_data),
      data_out => gamma_data
    );

  -- Increments the wait counter.
  wait_proc : process(clk)
  begin
    if rising_edge(clk) then
      if wait_en = '0' then
        wait_ctr <= 0;
      else
        wait_ctr <= wait_ctr + 1;
      end if;
    end if;
  end process wait_proc;

  -- Updates the PWM counter.
  pwm_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        pwm_ctr <= 0;
      elsif pwm_inc = '1' then
        if pwm_ctr = pwm_ctr'high then
          pwm_ctr <= 0;
        else
          pwm_ctr <= pwm_ctr + 1;
        end if;
      end if;
    end if;
  end process pwm_proc;

  -- Updates the display address according to the increment flags.
  addr_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        address_ctr <= (others => '0');
      elsif col_inc = '1' then
        if pwm_inc = '1' and row_inc = '0' then
          address_ctr <= address_ctr(ADDR_WIDTH-1 downto 3) & "000";
        else
          address_ctr <= address_ctr + 1;
        end if;
      end if;
    end if;
  end process addr_proc;

  -- The main process that updates the internal registers for the display.
  main_proc : process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= RESET_STATE;
        shift_reg <= (others => '0');
        cols_reg <= (others => '0');
      else
        -- Update the current state.
        state <= next_state;

        -- Reset the row address when latching a new row.
        if latch = '1' and oe = '1' then
          row_addr_reg <= address_ctr(ADDR_WIDTH-1 downto ADDR_WIDTH-3);
        end if;

        -- Load display data into the column register.
        if load = '1' then
          shift_reg <= led & shift_reg(DISPLAY_WIDTH-1 downto 1);
        end if;

        -- Latch the column register.
        if latch = '1' then
          cols_reg <= shift_reg;
        end if;
      end if;
    end if;
  end process main_proc;

  -- The combinatorial process for the state machine.
  comb_proc : process(state, address_ctr, pwm_ctr, wait_ctr, oe) is
  begin
    -- Default register assignments.
    next_state <= state;
    latch      <= '0';
    load       <= '0';
    oe         <= '0';
    wait_en    <= '0';
    pwm_inc    <= '0';
    col_inc    <= '0';
    row_inc    <= '0';

    case state is
    -- Reset the state machine.
    when RESET_STATE =>
      next_state <= LOAD_STATE;

    -- Load the LED bit into the shift register.
    when LOAD_STATE =>
      load <= '1';

      if address_ctr(2 downto 0) = "111" then -- end of row
        next_state <= LATCH_STATE;
      else
        next_state <= ADDR_STATE;
      end if;

    -- Update the address counter.
    when ADDR_STATE =>
      col_inc <= '1';

      if address_ctr(2 downto 0) = "111" then -- end of row
        pwm_inc <= '1';
      end if;

      if pwm_ctr = pwm_ctr'high then -- end of PWM cycle
        row_inc <= '1';
      end if;

      next_state <= WAIT_STATE;

    -- Wait for the memory and gamma correction to finish outputting their
    -- data.
    when WAIT_STATE =>
      if wait_ctr = wait_ctr'high then
        if oe = '1' then
          oe <= '0';
        end if;

        next_state <= LOAD_STATE;
      else
        wait_en <= '1';
      end if;

    -- Latch the current data into the columns register.
    when LATCH_STATE =>
      latch <= '1';

      if pwm_ctr = 0 then -- beginning of PWM cycle
        oe <= '1';
      end if;

      next_state <= ADDR_STATE;
    end case;
  end process comb_proc;

  -- Set the RAM address.
  ram_addr <= address_ctr;

  -- PWM the led bit.
  led <= '1' when pwm_ctr < gamma_data else '0';

  row_addr <= row_addr_reg;

  -- Decode the rows output.
  with row_addr_reg select
    matrix_rows <= "10000000" when "111",
                   "01000000" when "110",
                   "00100000" when "101",
                   "00010000" when "100",
                   "00001000" when "011",
                   "00000100" when "010",
                   "00000010" when "001",
                   "00000001" when others;

  -- Set the columns out.
  matrix_cols <= cols_reg when (oe = '0') else (others => '0');
end arch;
