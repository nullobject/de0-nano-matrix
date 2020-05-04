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
use ieee.math_real.all;

-- This block applies gamma correction to the input value on every rising clock
-- edge.
entity gamma is
  generic (
    -- The gamma value.
    GAMMA : real := 1.0;

    -- The width of the colour value.
    DATA_WIDTH : natural := 8
  );
  port (
    -- clock
    clk : in std_logic;

    -- data IO
    data_in  : in unsigned(DATA_WIDTH-1 downto 0);
    data_out : out unsigned(DATA_WIDTH-1 downto 0)
  );
end gamma;

architecture arch of gamma is
  type lut_type is array(2**DATA_WIDTH-1 downto 0) of unsigned(DATA_WIDTH-1 downto 0);

  function init_lut(c : natural; g : real) return lut_type is
    variable lut_var : lut_type;
    variable lut_element : natural;
  begin
    for i in 0 to 2**c-1 loop
      lut_element := natural(real(2**c-1) * ((real(i)/(real(2**c-1)))**g));
      lut_var(i) := to_unsigned(lut_element, c);
    end loop;
    return lut_var;
  end init_lut;

  constant gamma_lut : lut_type := init_lut(DATA_WIDTH, GAMMA);
begin
  process(clk)
  begin
    if rising_edge(clk) then
      data_out <= gamma_lut(to_integer(data_in));
    end if;
  end process;
end arch;
