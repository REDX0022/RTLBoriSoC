-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\mem.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


library WORK;
use work.mem_pack.all; -- Import the memory package
-- synthesis translate_off
use WORK.def_pack.all; -- Import the definitions package
use WORK.init_pack.all; -- Import the initialization package
use WORK.IO_pack.all; -- Import the IO package
--synthesis translate_on

--TODO : Move read one cycle later to simulate actual behaviour , might not be needed


entity mem is
    generic (
        SIMULATION : boolean := false
    );
    port (
        clk     : in  std_logic := '0';
        en      : in  std_logic := '0'; -- Enable signal for write operation
        addr    : in  std_logic_vector(31 downto 0) := (others => '0');
        datain  : in  std_logic_vector(31 downto 0) := (others => '0');
        dataout : out std_logic_vector(31 downto 0) := (others => '0');
        addrPC   : in  std_logic_vector(31 downto 0) := (others => '0');
        instrout : out std_logic_vector(31 downto 0) := (others => '0')
        -- synthesis translate_off
        ;
        --mem_sim  : in ram_type; -- Memory simulation interface
        --sim_dump : out ram_type;
        sim_init : in std_logic; -- Simulation initialization signal
        sim_dump_en : in std_logic -- Enable memory dump for simulation
        -- synthesis translate_on
    );
end entity;

architecture RTL of mem is
    signal ram : ram_type
        -- synthesis translate_off
        := mem_to_ram(init_mem)
        -- synthesis translate_on
    ;
begin

    -- Data port (Port A): Read/Write, word-aligned addressing
    process(clk)
        variable word_addr : integer range 0 to ram'high;
    begin
        if rising_edge(clk) then
            -- Convert byte address to word address (drop 2 LSBs)
            word_addr := to_integer(unsigned(addr(15 downto 2)));
            if en = '1' then
                ram(word_addr) <= datain;
            end if;
            dataout <= ram(word_addr);
        end if;
    end process;

    -- Instruction port (Port B): Read-only, word-aligned addressing
    process(clk)
        variable word_addr_pc : integer range 0 to ram'high;
    begin
        if rising_edge(clk) then
            -- Convert byte address to word address (drop 2 LSBs)
            word_addr_pc := to_integer(unsigned(addrPC(15 downto 2)));
            instrout <= ram(word_addr_pc);
        end if;
    end process;

    -- synthesis translate_off
    -- Simulation-only initialization and dump
    sim_init_block: if SIMULATION generate
        process(ram(1))
        begin
            report "First byte of RAM: " & to_hstring(to_bitvector(ram(1)));
        end process;

        process(sim_dump_en)
        begin
            if( sim_dump_en = '1' ) then
                dump_memory(dump_path, ram_to_mem(ram));
            end if;
        end process;
    end generate;
    -- synthesis translate_on

end architecture;