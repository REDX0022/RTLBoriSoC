library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- You must define a reusable array type for vector arrays
package MUX_types is
    type vector_array is array (natural range <>) of std_logic_vector;
end package;

use work.MUX_types.all;

entity MUX is
    generic (
        N : natural := 2; -- 2 bits → 4 elements
        w : natural := 8  -- Width of each input
    );
    port (
        sel     : in std_logic_vector(N-1 downto 0); -- N-bit select
        datain  : in vector_array(0 to 2**N - 1)(w - 1 downto 0); -- custom type
        dataout : out std_logic_vector(w - 1 downto 0)
    );
end entity;

architecture RTL of MUX is
begin
    process(sel, datain)
    begin
        dataout <= (others => '0'); -- default value
        if to_integer(unsigned(sel)) < datain'length then
            dataout <= datain(to_integer(unsigned(sel)));
        end if;
    end process;
end RTL;
