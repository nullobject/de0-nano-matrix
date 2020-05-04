-- Copyright (c) 2019 Josh Bassett
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

library altera_mf;
use altera_mf.altera_mf_components.all;

entity dual_port_ram is
  generic (
    ADDR_WIDTH : natural := 8;
    DATA_WIDTH : natural := 8
  );
  port (
    -- clock
    clk : in std_logic;

    -- chip select
    cs : in std_logic := '1';

    -- port A (write)
    addr_a : in unsigned(ADDR_WIDTH-1 downto 0);
    din_a  : in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    we_a   : in std_logic := '1';

    -- port B (read)
    addr_b : in unsigned(ADDR_WIDTH-1 downto 0);
    dout_b : out std_logic_vector(DATA_WIDTH-1 downto 0);
    re_b   : in std_logic := '1'
  );
end dual_port_ram;

architecture arch of dual_port_ram is
  signal q : std_logic_vector(DATA_WIDTH-1 downto 0);
begin
  altsyncram_component : altsyncram
  generic map (
    address_reg_b                      => "CLOCK0",
    clock_enable_input_a               => "BYPASS",
    clock_enable_input_b               => "BYPASS",
    clock_enable_output_a              => "BYPASS",
    clock_enable_output_b              => "BYPASS",
    indata_reg_b                       => "CLOCK0",
    intended_device_family             => "Cyclone V",
    lpm_type                           => "altsyncram",
    numwords_a                         => 2**ADDR_WIDTH,
    numwords_b                         => 2**ADDR_WIDTH,
    operation_mode                     => "DUAL_PORT",
    outdata_aclr_a                     => "NONE",
    outdata_aclr_b                     => "NONE",
    outdata_reg_a                      => "UNREGISTERED",
    outdata_reg_b                      => "UNREGISTERED",
    power_up_uninitialized             => "FALSE",
    rdcontrol_reg_b                    => "CLOCK0",
    read_during_write_mode_mixed_ports => "OLD_DATA",
    width_a                            => DATA_WIDTH,
    width_b                            => DATA_WIDTH,
    width_byteena_a                    => 1,
    width_byteena_b                    => 1,
    widthad_a                          => ADDR_WIDTH,
    widthad_b                          => ADDR_WIDTH
  )
  port map (
    address_a => std_logic_vector(addr_a),
    address_b => std_logic_vector(addr_b),
    clock0    => clk,
    wren_a    => cs and we_a,
    rden_b    => cs and re_b,
    data_a    => din_a,
    q_b       => q
  );

  -- output
  dout_b <= q when cs = '1' else (others => '0');
end architecture arch;
