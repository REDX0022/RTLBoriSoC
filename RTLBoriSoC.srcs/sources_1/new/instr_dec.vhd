library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


library WORK;
use work.MUX_types.all; -- Import the MUX types package


--this does not work at the end, we need a double input double output ALU
entity instr_dec is
    port(
        reg_wen: out std_logic;
        buffer_wen: out std_logic;
        instr_wen: out std_logic;
        PC_wen: out std_logic;
        ALU_res_sel: out std_logic_vector(2 downto 0);
        adder_sp_sel: out std_logic;
        imm_sel: out std_logic_vector(1 downto 0);
        op2_sel: out std_logic;
        rs1_sel: out std_logic_vector(4 downto 0);
        rs2_sel: out std_logic_vector(4 downto 0);
        rd_sel: out std_logic_vector(4 downto 0);
        funct7: out std_logic_vector(6 downto 0);
        imm: out std_logic_vector(19 downto 0);
        branch_in: in std_logic;
        branch_out: out std_logic;
        instr: in std_logic_vector(31 downto 0); -- Input instruction
        branch_sel: in std_logic_vector(2 downto 0) -- Branch selector
    );
    
    end entity;


architecture RTL of instr_dec is
    constant OP_code: std_logic_vector(6 downto 0) := "0110011";
    constant OPIMM_code: std_logic_vector(6 downto 0) := "0010011";
    constant LUI_code: std_logic_vector(6 downto 0) := "0110111";
    constant AIUPC_code: std_logic_vector(6 downto 0) :="0010111";
    constant JAL_code: std_logic_vector(6 downto 0) :="1101111";
    constant JALR_code: std_logic_vector(6 downto 0) :="1100111";
    constant BRANCH_code: std_logic_vector(6 downto 0) :="1100011";
    constant LOAD_code: std_logic_vector(6 downto 0) :="0000011";
    constant STORE_code: std_logic_vector(6 downto 0) :="0100011";

    --signal instr: std_logic_vector(31 downto 0);
    
    signal OP_sig: std_logic;
    signal OPIMM_sig: std_logic;
    signal LUI_sig: std_logic;
    signal AIUPC_sig: std_logic;
    signal JAL_sig: std_logic;
    signal JALR_sig: std_logic;
    signal BRANCH_sig: std_logic;
    signal LOAD_sig: std_logic;
    signal STORE_sig: std_logic;
    signal J: std_logic;
    signal B: std_logic;
    begin
    decode_opcode: process(instr) is
        begin
            --this is just a big lut
            case instr(6 downto 0) is
                when OP_code =>
                    rd_sel <= instr(11 downto 7);
                    rs1_sel <= instr(19 downto 15);
                    rs2_sel <= instr(24 downto 20);
                    funct7 <= instr(31 downto 25);
                    ALU_res_sel <= instr(14 downto 12); 
                    op2_sel <= '0'; -- ALU second operand is rs2
                    adder_sp_sel <= '0';
                    imm <= (others => '0');
                    imm_sel <= (others => '0');
                when OPIMM_code =>
                    rd_sel      <= instr(11 downto 7);
                    rs1_sel     <= instr(19 downto 15);
                    rs2_sel     <= (others => '0');
                    op2_sel     <= '1'; -- ALU second operand is immediate
                    imm         <= X"00" & instr(31 downto 20); -- this is quick might be inferred wrong
                    funct7      <= instr(31 downto 25); -- just the 30 bit is used for subtr and SRA
                    imm_sel     <= "00"; -- 12 bit signed
                    adder_sp_sel<= '0'; 
                    ALU_res_sel <= instr(14 downto 12); -- this is made such that we dont need a translator for OP and OPIMM
                    reg_wen     <= '0';
                    buffer_wen  <= '0';
                    instr_wen   <= '0';
                    PC_wen      <= '0';
                when others =>
                    rd_sel      <= (others => '0');
                    rs1_sel     <= (others => '0');
                    rs2_sel     <= (others => '0');
                    funct7      <= (others => '0');
                    ALU_res_sel <= (others => '0');
                    op2_sel     <= '0';
                    adder_sp_sel<= '0';
                    imm         <= (others => '0');
                    imm_sel     <= (others => '0');
            end case;

    end process; 
    branch_out <= (branch_in and B) or J; --branch if conditional and success check, or just unconditional jumps
end architecture RTL;