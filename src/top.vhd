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

entity top is
  port (
    -- 50MHz clock
    clk : in std_logic;

    -- display rows/columns
    rows : out std_logic_vector(7 downto 0);
    cols : out std_logic_vector(7 downto 0)
  );
end top;

architecture arch of top is
  constant RAM_ADDR_WIDTH : natural := 6;
  constant RAM_DATA_WIDTH : natural := 8;

  constant DISPLAY_ADDR_WIDTH : natural := 6;
  constant DISPLAY_DATA_WIDTH : natural := 8;

  constant DISPLAY_WIDTH  : natural := 8;
  constant DISPLAY_HEIGHT : natural := 8;

  signal reset : std_logic := '0';

  signal ram_addr_a, ram_addr_b : unsigned(RAM_ADDR_WIDTH-1 downto 0);
  signal ram_din_a, ram_dout_b : std_logic_vector(RAM_DATA_WIDTH-1 downto 0);
  signal ram_we_a : std_logic;

  signal display_addr : unsigned(DISPLAY_ADDR_WIDTH-1 downto 0);
  signal display_row_addr : unsigned(2 downto 0);
begin
  -- pll : entity work.pll
  -- port map (
  --   inclk0 => clk,
  --   c0     => sys_clk,   -- 48MHz
  --   c1     => sdram_clk, -- 48MHz
  --   locked => open
  -- );

  -- ram : entity work.dual_port_ram
  --   generic map (
  --     ADDR_WIDTH => RAM_ADDR_WIDTH,
  --     DATA_WIDTH => RAM_DATA_WIDTH
  --   )
  --   port map (
  --     clk    => clk,
  --     addr_a => ram_addr_a,
  --     din_a  => ram_din_a,
  --     we_a   => ram_we_a,
  --     addr_b => ram_addr_b,
  --     dout_b => ram_dout_b
  --   );

  ram : entity work.single_port_rom
    generic map (
      ADDR_WIDTH => RAM_ADDR_WIDTH,
      DATA_WIDTH => RAM_DATA_WIDTH,
      INIT_FILE  => "rom/image.mif"
    )
    port map (
      clk  => clk,
      addr => ram_addr_b,
      dout => ram_dout_b
    );

  display : entity work.display
    generic map (
      ADDR_WIDTH     => DISPLAY_ADDR_WIDTH,
      DATA_WIDTH     => DISPLAY_DATA_WIDTH,
      DISPLAY_WIDTH  => DISPLAY_WIDTH,
      DISPLAY_HEIGHT => DISPLAY_HEIGHT
    )
    port map (
      reset        => reset,
      clk          => clk,
      ram_addr     => display_addr,
      ram_data     => ram_dout_b,
      matrix_rows  => rows,
      matrix_cols  => cols,
      row_addr     => display_row_addr
    );

  ram_addr_b <= display_addr;
end arch;
