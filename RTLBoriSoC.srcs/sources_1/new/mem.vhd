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
    -- Data port signals
    signal addr_cut : std_logic_vector(15 downto 0);
    signal word_addr : integer range 0 to ram'high;
    signal byte_offset : integer range 0 to 3;
    signal dataout_int : std_logic_vector(31 downto 0);

    -- Instruction port signals
    signal addrPC_cut : std_logic_vector(15 downto 0);
    signal word_addr_pc : integer range 0 to ram'high;
    signal byte_offset_pc : integer range 0 to 3;
    signal instrout_int : std_logic_vector(31 downto 0);
begin
    -- Data port address decode
    addr_cut <= addr(15 downto 0);
    word_addr <= to_integer(unsigned(addr_cut(15 downto 2)));
    byte_offset <= to_integer(unsigned(addr_cut(1 downto 0)));

    -- Instruction port address decode
    addrPC_cut <= addrPC(15 downto 0);
    word_addr_pc <= to_integer(unsigned(addrPC_cut(15 downto 2)));
    byte_offset_pc <= to_integer(unsigned(addrPC_cut(1 downto 0)));

    -- Synchronous write (data port only)
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                ram(to_integer(unsigned(addr_cut))) <= datain;
            end if;
        end if;
    end process;

    -- Little-endian, byte-addressed data read (dataout)
    process(ram, word_addr, byte_offset)
        variable bytes : std_logic_vector(7 downto 0);
        variable temp_data : std_logic_vector(31 downto 0);
    begin
        for i in 0 to 3 loop
            if (byte_offset + i) < 4 then
                bytes := ram(word_addr)((8*(byte_offset + i) + 7) downto 8*(byte_offset + i));
            else
                bytes := ram(word_addr + 1)((8*((byte_offset + i) mod 4) + 7) downto 8*((byte_offset + i) mod 4));
            end if;
            temp_data(8*i+7 downto 8*i) := bytes;
        end loop;
        dataout_int <= temp_data;
    end process;

    -- Little-endian, byte-addressed instruction read (instrout)
    process(ram, word_addr_pc, byte_offset_pc)
        variable bytes : std_logic_vector(7 downto 0);
        variable temp_instr : std_logic_vector(31 downto 0);
    begin
        for i in 0 to 3 loop
            if (byte_offset_pc + i) < 4 then
                bytes := ram(word_addr_pc)((8*(byte_offset_pc + i) + 7) downto 8*(byte_offset_pc + i));
            else
                bytes := ram(word_addr_pc + 1)((8*((byte_offset_pc + i) mod 4) + 7) downto 8*((byte_offset_pc + i) mod 4));
            end if;
            temp_instr(8*i+7 downto 8*i) := bytes;
        end loop;
        instrout_int <= temp_instr;
    end process;

    dataout  <= dataout_int;
    instrout <= instrout_int;

    -- synthesis translate_off
    -- Simulation-only initialization and dump
    sim_init_block: if SIMULATION generate
        process(ram(1))
        begin
            
            -- It can be removed if not needed
         
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