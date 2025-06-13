-- filepath: c:\Users\ceran\Documents\RTLBoriSoC\RTLBoriSoC.srcs\sources_1\new\regs.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use WORk.MUX_types.all;
use WORK.mem_pack.all;

entity regs is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        en       : in  std_logic;
        sel1     : in  std_logic_vector(4 downto 0);
        sel2     : in  std_logic_vector(4 downto 0);
        sel3     : in  std_logic_vector(4 downto 0);
        selin    : in  std_logic_vector(4 downto 0); -- new write select port
        datain   : in  std_logic_vector(31 downto 0);
        dataout1 : out std_logic_vector(31 downto 0);
        dataout2 : out std_logic_vector(31 downto 0);
        dataout3 : out std_logic_vector(31 downto 0)
        -- synthesis translate_off
        ;
        reg_sim : out vector_array(0 to 31)  -- Simulation interface for registers
        -- synthesis translate_on 
    );
end entity;



architecture RTL of regs is
    --type regs_type is array (0 to 31) of std_logic_vector(31 downto 0);
    -- Explicit reg component declaration
    signal reg_array: vector_array(0 to 31) := (others => (others => '0'));
    signal en_internal: std_logic_vector(0 to 31);
    component reg is
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
    end component;

    -- Explicit MUX component declaration
    component MUX is
        generic (
            N : natural
        );
        port (
            sel     : in std_logic_vector(N-1 downto 0);
            datain  : in vector_array(0 to 2**N-1);
            dataout : out std_logic_vector(31 downto 0)
        );
    end component;

    -- Array of register outputs

begin
    -- Generate 32 registers
    gen_regs: for i in 0 to 31 generate
        reg_inst: REG
            generic map (
                w => 32,
                rising => true  -- they are written at the end of the cycle
            )
            port map (
                clk => clk,
                rst => rst,
                en => en_internal(i),
                datain => datain,
                dataout => reg_array(i)
            );

        zero_reg_en: if i = 0 generate
            en_internal(i) <= '0';
        end generate;
        nonzero_reg_en: if i /= 0 generate
            en_internal(i) <= '1' when selin = std_logic_vector(to_unsigned(i, 5)) and en = '1' else '0';
        end generate;
    end generate;
    
    -- Output multiplexers using MUX component
    mux1_inst: MUX
        generic map (
            N => 5
        )
        port map (
            sel     => sel1,
            datain  => reg_array,
            dataout => dataout1
        );

    mux2_inst: MUX
        generic map (
            N => 5
        )
        port map (
            sel     => sel2,
            datain  => reg_array,
            dataout => dataout2
        );

    mux3_inst: MUX
        generic map (
            N => 5
        )
        port map (
            sel     => sel3,
            datain  => reg_array,
            dataout => dataout3
        );
    -- Simulation interface for registers
    -- synthesis translate_off
    process(reg_array)
    begin
        reg_sim <= reg_array;
    end process;
    -- synthesis translate_on

end architecture;
