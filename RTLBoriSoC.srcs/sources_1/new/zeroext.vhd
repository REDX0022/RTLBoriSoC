-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\zeroext.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity zeroext is
    generic (
        w: integer -- should be specified later
    );
    port (
        imm : in std_logic_vector(w-1 downto 0); -- w-bit immediate input
        imm_extended : out std_logic_vector(31 downto 0) -- 32-bit zero-extended output
    );
end entity;

architecture RTL of zeroext is
begin
    process(imm)
    variable ext: std_logic_vector(31-w downto 0);
    begin
        ext := (others => '0'); -- zero extend the immediate
        imm_extended <= ext & imm; -- concatenate the extended part with the original immediate
    end process;
end architecture RTL;