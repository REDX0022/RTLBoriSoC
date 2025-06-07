-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\INCf.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity INCf is
    port (
        datain  : in  std_logic_vector(31 downto 0);
        dataout : out std_logic_vector(31 downto 0)
    );
end entity;

architecture RTL of INCf is
begin
    dataout <= std_logic_vector(unsigned(datain) + 4);
end architecture RTL;