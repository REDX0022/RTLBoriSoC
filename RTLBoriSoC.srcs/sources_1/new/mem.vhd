-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\mem.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package mem_pack is
    type ram_type is array (0 to 2**16-1) of std_logic_vector(31 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use work.mem_pack.all; -- Import the memory package

entity mem is
    generic (
        SIMULATION : boolean := false
    );
    port (
        clk     : in  std_logic;
        en      : in  std_logic;
        addr    : in  std_logic_vector(31 downto 0);
        datain  : in  std_logic_vector(31 downto 0);
        dataout : out std_logic_vector(31 downto 0)
        -- synthesis translate_off
        ;
        mem_sim  : in ram_type; -- Memory simulation interface
        sim_dump : out ram_type;
        sim_init : in std_logic; -- Simulation initialization signal
        sim_dump_en : in std_logic -- Enable memory dump for simulation
        -- synthesis translate_on
    );
end entity;

architecture RTL of mem is
    signal ram : ram_type;
    signal addr_cut : std_logic_vector(15 downto 0);

    -- synthesis translate_off
    -- (simulation-only signals here, if any)
    -- synthesis translate_on

begin
    addr_cut <= addr(15 downto 0);

    -- Synchronous write
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                ram(to_integer(unsigned(addr_cut))) <= datain;
            end if;
        end if;
    end process;

    -- synthesis translate_off
    -- Simulation-only initialization and dump
    sim_init_block: if SIMULATION generate
        process(sim_init)
        begin
            if sim_init = '1' then
                for i in 0 to 2**16-1 loop
                    ram(i) <= mem_sim(i);
                end loop;
            end if;
        end process;
        process(sim_dump_en)
        begin
            if( sim_dump_en = '1' ) then
                sim_dump <= ram;
            end if;
        end process;
    end generate;
    -- synthesis translate_on

    -- Asynchronous read
    dataout <= ram(to_integer(unsigned(addr_cut)));

end architecture;