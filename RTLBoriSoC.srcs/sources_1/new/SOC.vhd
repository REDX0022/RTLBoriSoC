-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\SOC.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library WORK;
use WORK.mem_pack.all; -- Import the memory package
use WORK.MUX_types.all; -- Import the MUX types package

entity SOC is
    generic (
        SIMULATION : boolean := false
    );
    port (
        clk      : in std_logic := '0';  -- Clock signal
        rst      : in std_logic := '0'  -- Reset signal
        -- synthesis translate_off
        ;
        sim_init : in std_logic;      -- Simulation initialization signal
        sim_instr : out std_logic_vector(31 downto 0); -- Simulation instruction trace output
        sim_dump_en : in std_logic; -- Enable memory dump for simulation
        reg_sim  : out vector_array(0 to 31); -- Simulation interface for registers
        PC_sim  : out std_logic_vector(31 downto 0) -- Simulation output for PC
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
            datain    : in std_logic_vector(31 downto 0);
            instrin : in std_logic_vector(31 downto 0); -- Input instruction
            addrPC   : out std_logic_vector(31 downto 0); -- Address for PC    
            mem_wen : out std_logic := '0' -- Memory write enable signal
            
            -- synthesis translate_off
            ;
            sim_instr : out std_logic_vector(31 downto 0); -- Simulation instruction trace output
            reg_sim  : out vector_array(0 to 31); -- Simulation interface for registers
            PC_sim  : out std_logic_vector(31 downto 0) -- Simulation output for PC
            -- synthesis translate_on
        );
    end component;


    component mem is
        generic (
            SIMULATION : boolean := false
        );
        port(
            clk        : in  std_logic := '0';
            en         : in  std_logic := '0'; -- Enable signal for write operation
            addr       : in  std_logic_vector(31 downto 0) := (others => '0'); 
            datain     : in  std_logic_vector(31 downto 0) := (others => '0');
            dataout    : out std_logic_vector(31 downto 0) := (others => '0');
            addrPC   : in  std_logic_vector(31 downto 0) := (others => '0');
            instrout : out std_logic_vector(31 downto 0) := (others => '0')
            -- synthesis translate_off
            ;
            --mem_sim    : in  ram_type; -- Memory simulation interface
            --sim_dump   : out ram_type;
            sim_init   : in  std_logic;
            sim_dump_en : in  std_logic -- Enable memory dump for simulation
            -- synthesis translate_on
        );
    end component;

    -- Internal signals to connect CPU and MEM
    signal mem_wen_sig : std_logic := '0'; -- Memory write enable signal
    signal addr_sig    : std_logic_vector(31 downto 0) := (others => '0');
    signal dataout_sig : std_logic_vector(31 downto 0) := (others => '0');
    signal datain_sig  : std_logic_vector(31 downto 0) := (others => '0');
    signal instrout_sig : std_logic_vector(31 downto 0) := (others => '0');
    signal addrPC_sig : std_logic_vector(31 downto 0) := (others => '0');

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
            datain    => dataout_sig,
            instrin   => instrout_sig, -- Input instruction
            addrPC   => addrPC_sig, -- Address for PC
            mem_wen => mem_wen_sig
            -- synthesis translate_off
            ,
            sim_instr => sim_instr_sig,
            reg_sim => reg_sim,
            PC_sim => PC_sim

            -- synthesis translate_on
        );

    mem_inst: mem
        generic map (
            SIMULATION => SIMULATION
        )
        port map (
            clk      => clk,
            en       => mem_wen_sig, --disable memory writes for now
            addr     => addr_sig,
            datain   => datain_sig,
            dataout  => dataout_sig,
            instrout => instrout_sig,
            addrPC   => addrPC_sig
            -- synthesis translate_off
            ,
            --mem_sim  => mem_sim,
            --sim_dump => sim_dump,
            sim_init => sim_init,
            sim_dump_en => sim_dump_en
            -- synthesis translate_on
        );

    -- synthesis translate_off
    sim_trace: if SIMULATION generate
        process(sim_instr_sig)
        begin
            
               
                sim_instr <= sim_instr_sig;
            
        end process;
    end generate;
    -- synthesis translate_on

end architecture Structural;