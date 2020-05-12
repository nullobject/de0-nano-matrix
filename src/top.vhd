--   __   __     __  __     __         __
--  /\ "-.\ \   /\ \/\ \   /\ \       /\ \
--  \ \ \-.  \  \ \ \_\ \  \ \ \____  \ \ \____
--   \ \_\\"\_\  \ \_____\  \ \_____\  \ \_____\
--    \/_/ \/_/   \/_____/   \/_____/   \/_____/
--   ______     ______       __     ______     ______     ______
--  /\  __ \   /\  == \     /\ \   /\  ___\   /\  ___\   /\__  _\
--  \ \ \/\ \  \ \  __<    _\_\ \  \ \  __\   \ \ \____  \/_/\ \/
--   \ \_____\  \ \_____\ /\_____\  \ \_____\  \ \_____\    \ \_\
--    \/_____/   \/_____/ \/_____/   \/_____/   \/_____/     \/_/
--
-- https://joshbassett.info
-- https://twitter.com/nullobject
-- https://github.com/nullobject
--
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

entity matrix is
  port (
    -- 50MHz clock
    clk : in std_logic;

    -- buttons
    key : in std_logic_vector(1 downto 0);

    -- leds
    led : out std_logic_vector(7 downto 0);

    -- display rows/columns
    rows : out std_logic_vector(7 downto 0);
    cols : out std_logic_vector(7 downto 0)
  );
end matrix;

architecture arch of matrix is
  constant PROG_ROM_ADDR_WIDTH  : natural := 14;
  constant WORK_RAM_ADDR_WIDTH  : natural := 14;
  constant VIDEO_RAM_ADDR_WIDTH : natural := 6;

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

  -- chip select signals
  signal prog_rom_cs  : std_logic;
  signal work_ram_cs  : std_logic;
  signal video_ram_cs : std_logic;
  signal led_cs       : std_logic;

  -- registers
  signal led_reg : std_logic_vector(7 downto 0);

  signal display_ram_addr : unsigned(VIDEO_RAM_ADDR_WIDTH-1 downto 0);
  signal display_ram_data : std_logic_vector(7 downto 0);
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

  prog_rom : entity work.single_port_rom
  generic map(
    ADDR_WIDTH => PROG_ROM_ADDR_WIDTH,
    DATA_WIDTH => 8,
    INIT_FILE  => "rom/prog_rom.mif"
  )
  port map(
    clk  => clk,
    cs   => prog_rom_cs and not cpu_mreq_n and not cpu_rd_n,
    addr => cpu_addr(PROG_ROM_ADDR_WIDTH-1 downto 0),
    dout => rom_dout
  );

  work_ram : entity work.single_port_ram
  generic map(
    ADDR_WIDTH => WORK_RAM_ADDR_WIDTH,
    DATA_WIDTH => 8
  )
  port map(
    clk  => clk,
    cs   => work_ram_cs and not cpu_mreq_n,
    addr => cpu_addr(WORK_RAM_ADDR_WIDTH-1 downto 0),
    din  => cpu_dout,
    dout => work_ram_dout,
    we   => not cpu_wr_n
  );

  video_ram : entity work.dual_port_ram
    generic map (
      ADDR_WIDTH => VIDEO_RAM_ADDR_WIDTH,
      DATA_WIDTH => 8
    )
    port map (
      clk    => clk,
      cs_a   => video_ram_cs,
      addr_a => cpu_addr(5 downto 0),
      din_a  => cpu_dout,
      we_a   => not cpu_wr_n,
      addr_b => display_ram_addr,
      dout_b => display_ram_data
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

  set_led_register : process (clk)
  begin
    if rising_edge(clk) then
      if led_cs = '1' and cpu_ioreq_n = '0' and cpu_wr_n = '0' then
        led_reg <= cpu_dout;
      end if;
    end if;
  end process;

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
      ram_addr     => display_ram_addr,
      ram_data     => display_ram_data,
      matrix_rows  => rows,
      matrix_cols  => cols,
      row_addr     => open
    );

  -- mux CPU data input
  cpu_din <= rom_dout or work_ram_dout;

  --  address    description
  -- ----------+-----------------
  -- 0000-3fff | program ROM
  -- 4000-7fff | work RAM
  -- 8000-803f | video RAM
  prog_rom_cs  <= '1' when cpu_addr >= x"0000" and cpu_addr <= x"3fff" else '0';
  work_ram_cs  <= '1' when cpu_addr >= x"4000" and cpu_addr <= x"7fff" else '0';
  video_ram_cs <= '1' when cpu_addr >= x"8000" and cpu_addr <= x"803f" else '0';
  led_cs       <= '1' when cpu_addr(7 downto 0) = x"00" else '0';

  -- set LED output
  led <= led_reg;
end arch;
