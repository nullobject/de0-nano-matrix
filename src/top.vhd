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

    -- buttons
    key : in std_logic_vector(1 downto 0);

    -- display rows/columns
    rows : out std_logic_vector(7 downto 0);
    cols : out std_logic_vector(7 downto 0)
  );
end top;

architecture arch of top is
  constant GFX_RAM_ADDR_WIDTH : natural := 6;
  constant GFX_RAM_DATA_WIDTH : natural := 8;

  constant DISPLAY_ADDR_WIDTH : natural := 6;
  constant DISPLAY_DATA_WIDTH : natural := 8;

  constant DISPLAY_WIDTH  : natural := 8;
  constant DISPLAY_HEIGHT : natural := 8;

  -- clock enable
  signal cen : std_logic;

  -- cpu reset
  signal reset : std_logic := '0';

  -- address bus
  signal cpu_addr	: unsigned(15 downto 0);

  -- data bus
  signal cpu_din	: std_logic_vector(7 downto 0);
  signal cpu_dout	: std_logic_vector(7 downto 0);

  -- i/o request: the address bus holds a valid address for an i/o read or
  -- write operation
  signal cpu_ioreq_n : std_logic;

  -- memory request: the address bus holds a valid address for a memory read or
  -- write operation
  signal cpu_mreq_n : std_logic;

  -- refresh memory: the CPU asserts this signal when it is refreshing
  -- a dynamic memory address
  signal cpu_rfsh_n : std_logic;

  -- read: ready to read data from the data bus
  signal cpu_rd_n : std_logic;

  -- write: the data bus contains a byte to write somewhere
  signal cpu_wr_n : std_logic;

  -- data output signals
  signal rom_dout      : std_logic_vector(7 downto 0);
  signal work_ram_dout : std_logic_vector(7 downto 0);
  signal gfx_ram_dout  : std_logic_vector(7 downto 0);

  -- chip select signals
  signal prog_rom_cs : std_logic;
  signal work_ram_cs : std_logic;
  signal gfx_ram_cs  : std_logic;

  signal work_ram_addr_a, work_ram_addr_b : unsigned(GFX_RAM_ADDR_WIDTH-1 downto 0);
  signal work_ram_din_a, work_ram_dout_b : std_logic_vector(GFX_RAM_DATA_WIDTH-1 downto 0);
  signal work_ram_we_a : std_logic;

  signal display_addr : unsigned(DISPLAY_ADDR_WIDTH-1 downto 0);
  signal display_row_addr : unsigned(2 downto 0);
begin
  clock_divider : entity work.clock_divider
  generic map (DIVISOR => 50)
  port map (clk => clk, cen => cen);

  -- Generate a reset pulse after powering on, or when KEY0 is pressed.
  --
  -- The Z80 needs to be reset after powering on, otherwise it may load garbage
  -- data from the address and data buses.
  reset_gen : entity work.reset_gen
  port map (
    clk  => clk,
    rin  => not key(0),
    rout => reset
  );

  -- display_rom : entity work.single_port_rom
  --   generic map (
  --     ADDR_WIDTH => GFX_RAM_ADDR_WIDTH,
  --     DATA_WIDTH => GFX_RAM_DATA_WIDTH,
  --     INIT_FILE  => "rom/image.mif"
  --   )
  --   port map (
  --     clk  => clk,
  --     addr => ram_addr_b,
  --     dout => ram_dout_b
  --   );

  prog_rom : entity work.single_port_rom
  generic map(
    ADDR_WIDTH => 12,
    DATA_WIDTH => 8,
    INIT_FILE  => "rom/blink.mif"
  )
  port map(
    clk  => clk,
    cs   => prog_rom_cs and not cpu_mreq_n and not cpu_rd_n,
    addr => cpu_addr(11 downto 0),
    dout => rom_dout
  );

  work_ram : entity work.single_port_ram
  generic map(
    ADDR_WIDTH => 12,
    DATA_WIDTH => 8
  )
  port map(
    clk  => clk,
    cs   => work_ram_cs and not cpu_mreq_n,
    addr => cpu_addr(11 downto 0),
    din  => cpu_dout,
    dout => work_ram_dout,
    we   => not cpu_wr_n
  );

  gfx_ram : entity work.dual_port_ram
    generic map (
      ADDR_WIDTH => GFX_RAM_ADDR_WIDTH,
      DATA_WIDTH => GFX_RAM_DATA_WIDTH
    )
    port map (
      clk    => clk,
      cs_a   => work_ram_cs,
      addr_a => work_ram_addr_a,
      din_a  => work_ram_din_a,
      we_a   => work_ram_we_a,
      addr_b => work_ram_addr_b,
      dout_b => work_ram_dout_b
    );

  cpu : entity work.T80s
  port map(
    RESET_n     => not reset,
    CLK         => clk,
    CEN         => cen,
    INT_n       => '1',
    M1_n        => open,
    MREQ_n      => cpu_mreq_n,
    IORQ_n      => cpu_ioreq_n,
    RD_n        => cpu_rd_n,
    WR_n        => cpu_wr_n,
    RFSH_n      => cpu_rfsh_n,
    HALT_n      => open,
    BUSAK_n     => open,
    unsigned(A) => cpu_addr,
    DI          => cpu_din,
    DO          => cpu_dout
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
      ram_data     => work_ram_dout_b,
      matrix_rows  => rows,
      matrix_cols  => cols,
      row_addr     => display_row_addr
    );

  work_ram_addr_b <= display_addr;

  -- mux CPU data input
  cpu_din <= rom_dout or work_ram_dout or gfx_ram_dout;

  prog_rom_cs <= '1' when cpu_addr >= x"0000" and cpu_addr <= x"0fff" else '0';
  work_ram_cs <= '1' when cpu_addr >= x"1000" and cpu_addr <= x"1fff" else '0';
  gfx_ram_cs  <= '1' when cpu_addr >= x"2000" and cpu_addr <= x"203f" else '0';
end arch;