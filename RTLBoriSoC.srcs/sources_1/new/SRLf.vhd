-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\SRLf.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SRLf is
    port (
        a : in std_logic_vector(31 downto 0);
        shamt : in std_logic_vector(4 downto 0);
        outp : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of SRLf is
begin
    process(a, shamt)
    begin
        outp <= std_logic_vector(shift_right(unsigned(a), to_integer(unsigned(shamt))));
    end process;
end architecture RTL;