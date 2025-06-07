library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity reg is
    generic(
        w: natural;
        rising: boolean 
    );
    port(
        rst: in std_logic;
        clk: in std_logic;
        en: in std_logic;
        datain: in std_logic_vector(w-1 downto 0);
        dataout: out std_logic_vector(w-1 downto 0)
    );
end entity;

architecture RTL of reg is
    signal sto: std_logic_vector(w-1 downto 0);
begin

    rising_proc: if rising generate
        process(clk, rst)
        begin
            if rst = '1' then
                sto <= (others => '0');
            elsif rising_edge(clk) then
                if en = '1' then
                    sto <= datain;
                end if;
            end if;
        end process;
    end generate;

    falling_proc: if not rising generate
        process(clk, rst)
        begin
            if rst = '1' then
                sto <= (others => '0');
            elsif falling_edge(clk) then
                if en = '1' then
                    sto <= datain;
                end if;
            end if;
        end process;
    end generate;

    dataout <= sto;
end architecture RTL;