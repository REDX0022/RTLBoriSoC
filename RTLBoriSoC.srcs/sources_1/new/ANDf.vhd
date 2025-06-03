-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\ANDf.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ANDf is
    port (
        a : in std_logic_vector(31 downto 0);
        b : in std_logic_vector(31 downto 0);
        outp : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of ANDf is
begin
    outp <= a and b;
end architecture RTL;