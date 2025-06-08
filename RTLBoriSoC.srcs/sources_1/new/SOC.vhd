-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\SOC.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.mem_pack.all; -- Import the memory package

entity SOC is
    generic (
        SIMULATION : boolean := false
    );
    port (
        clk      : in std_logic;
        rst      : in std_logic
        -- synthesis translate_off
        ;
        mem_sim  : in ram_type;      -- Memory simulation interface
        sim_dump : out ram_type;     -- Memory dump for simulation
        sim_init : in std_logic;      -- Simulation initialization signal
        sim_instr : out std_logic_vector(31 downto 0); -- Simulation instruction trace output
        sim_dump_en : in std_logic -- Enable memory dump for simulation
        -- synthesis translate_on
    );
end entity;

architecture Structural of SOC is

    -- Explicit CPU component declaration
    component cpu is
        generic (
            SIMULATION : boolean := false
        );
        port(
            clk       : in std_logic;
            rst       : in std_logic;
            addrout   : out std_logic_vector(31 downto 0);
            dataout   : out std_logic_vector(31 downto 0);
            datain    : in std_logic_vector(31 downto 0)      
                
            -- synthesis translate_off
            ;
            sim_instr : out std_logic_vector(31 downto 0) -- Simulation instruction trace output
            -- synthesis translate_on
        );
    end component;

    -- Explicit MEM component declaration
    component mem is
        generic (
            SIMULATION : boolean := false
        );
        port(
            clk        : in  std_logic;
            en         : in  std_logic;
            addr       : in  std_logic_vector(31 downto 0);
            datain     : in  std_logic_vector(31 downto 0);
            dataout    : out std_logic_vector(31 downto 0)
            -- synthesis translate_off
            ;
            mem_sim    : in  ram_type; -- Memory simulation interface
            sim_dump   : out ram_type;
            sim_init   : in  std_logic;
            sim_dump_en : in  std_logic -- Enable memory dump for simulation
            -- synthesis translate_on
        );
    end component;

    -- Internal signals to connect CPU and MEM
    signal addr_sig    : std_logic_vector(31 downto 0) := (others => '0');
    signal dataout_sig : std_logic_vector(31 downto 0) := (others => '0');
    signal datain_sig  : std_logic_vector(31 downto 0) := (others => '0');

    -- synthesis translate_off
    signal sim_instr_sig : std_logic_vector(31 downto 0);
    -- synthesis translate_on

begin

    cpu_inst: cpu
        generic map (
            SIMULATION => SIMULATION
        )
        port map (
            clk       => clk,
            rst       => rst,
            addrout   => addr_sig,
            dataout   => datain_sig,
            datain    => dataout_sig
            -- synthesis translate_off
            ,
            sim_instr => sim_instr_sig
            -- synthesis translate_on
        );

    mem_inst: mem
        generic map (
            SIMULATION => SIMULATION
        )
        port map (
            clk      => clk,
            en       => '1',
            addr     => addr_sig,
            datain   => datain_sig,
            dataout  => dataout_sig
            -- synthesis translate_off
            ,
            mem_sim  => mem_sim,
            sim_dump => sim_dump,
            sim_init => sim_init,
            sim_dump_en => sim_dump_en
            -- synthesis translate_on
        );

    -- synthesis translate_off
    sim_trace: if SIMULATION generate
        process
        begin
            if rising_edge(clk) then
                wait for 0 ns; -- ensures you see the updated value after register update
                sim_instr <= sim_instr_sig;
            end if;
        end process;
    end generate;
    -- synthesis translate_on

end architecture Structural;