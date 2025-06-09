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
        funct3: out std_logic_vector(2 downto 0);
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
        --branch_sel: in std_logic_vector(2 downto 0); -- Branch selectoro
        regs_in_sel: out std_logic_vector(1 downto 0); -- this chooses between ALU_res, INC(PC), memory, and buffer
        AUIPC_or_branch_sel: out std_logic
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
            --imm_mux_in(0) <= imm12_signed; -- 12-bit signed immediate
            --imm_mux_in(1) <= imm12_unsigned; -- 12-bit unsigned immediate
            --imm_mux_in(2) <= imm20_signed; -- 20-bit signed immediate
            --imm_mux_in(3) <= imm20_upper; -- upper 20 immediate bits 
            case instr(6 downto 0) is
                when OP_code =>
                    rd_sel <= instr(11 downto 7);
                    rs1_sel <= instr(19 downto 15);
                    rs2_sel <= instr(24 downto 20);
                    funct7 <= instr(31 downto 25);
                    funct3 <= instr(14 downto 12); 
                    op2_sel <= '0'; -- ALU second operand is rs2
                    adder_sp_sel <= '0';
                    imm <= (others => '0');
                    imm_sel <= "00"; --12 bit signed
                    regs_in_sel <= "00";
                    AUIPC_or_branch_sel <= '0'; -- ALU result
                    J <= '0'; -- Not a jump instruction
                    B <= '0'; -- Not a branch instruction

                when OPIMM_code =>
                    rd_sel      <= instr(11 downto 7);
                    rs1_sel     <= instr(19 downto 15);
                    rs2_sel     <= (others => '0');
                    op2_sel     <= '1'; -- ALU second operand is immediate
                    imm         <= X"00" & instr(31 downto 20); -- this is quick might be inferred wrong
                    --funct7      <= instr(31 downto 25); -- just the 30 bit is used for subtr and SRA
                    imm_sel     <= "00"; -- 12 bit signed
                    adder_sp_sel<= '0'; 
                    funct3 <= instr(14 downto 12); -- this is made such that we dont need a translator for OP and OPIMM
                    reg_wen     <= '0';
                    buffer_wen  <= '0';
                    instr_wen   <= '0';
                    PC_wen      <= '0';
                    regs_in_sel <= "00"; -- ALU result
                    AUIPC_or_branch_sel <= '0'; -- ALU result
                    J <= '0'; -- Not a jump instruction
                    B <= '0'; -- Not a branch instruction
                when LUI_code =>
                    rd_sel      <= instr(11 downto 7);
                    rs1_sel     <= (others => '0'); --this must be 0 for the adder
                    rs2_sel     <= (others => '0');
                    funct7      <= (others => '0');
                    funct3 <= (others => '0');
                    op2_sel     <= '1'; 
                    AUIPC_or_branch_sel <= '0'; -- ALU result
                    adder_sp_sel<= '0';
                    imm         <= instr(31 downto 12); -- this is quick might be inferred wrong
                    imm_sel     <= "11"; -- 20 bit upper immediate
                    regs_in_sel <= "00"; -- ALU result
                    J <= '0'; -- Not a jump instruction
                    B <= '0'; -- Not a branch instruction
                when AIUPC_code =>
                    rd_sel      <= instr(11 downto 7);
                    rs1_sel     <= (others => '0');
                    rs2_sel     <= (others => '0');
                    funct7      <= (others => '0');
                    funct3 <= (others => '0');
                    op2_sel     <= '1'; --imm
                    AUIPC_or_branch_sel <= '1'; -- ALU result
                    adder_sp_sel<= '0';
                    imm         <= instr(31 downto 12); -- this is quick might be inferred wrong
                    imm_sel     <= "11"; -- 20 bit upper immediate
                    regs_in_sel <= "00"; -- ALU result
                    J <= '0'; -- Not a jump instruction
                    B <= '0'; -- Not a branch instruction
                --regs_in_mux_in(0) <= ALU_res; -- ALU result input
                --regs_in_mux_in(1) <= PC_inc_sig; -- Incremented PC input
                --regs_in_mux_in(2) <= datain; -- Memory input
                --regs_in_mux_in(3) <= (others => '0'); -- Buffer input, placeholder for future use 
                when JAL_code =>
                    rd_sel     <= instr(11 downto 7);
                    rs1_sel     <= (others => '0'); -- this must be 0 for the adder
                    rs2_sel     <= (others => '0');
                    funct7      <= (others => '0');
                    funct3 <= (others => '0');
                    op2_sel    <= '1'; --imm offset
                    AUIPC_or_branch_sel <= '1'; -- ALU result
                    adder_sp_sel <= '0';
                    imm        <= instr(31 downto 12);
                    imm_sel    <= "10"; -- 20 bit signed immediate
                    regs_in_sel <= "01"; -- PC incremented
                    J <= '1'; -- Set J for unconditional jump
                    B <= '0'; -- Not a branch instruction
                when JALR_code =>
                    rd_sel      <= instr(11 downto 7);
                    rs1_sel     <= instr(19 downto 15);
                    rs2_sel     <= (others => '0'); -- this must be 0 for the adder
                    funct7      <= (others => '0');
                    funct3      <= (others => '0');
                    op2_sel     <= '1'; --imm offset
                    AUIPC_or_branch_sel <= '1'; -- ALU result
                    adder_sp_sel <= '0';
                    imm         <= X"00" & instr(31 downto 20); -- this is quick might be inferred wrong
                    imm_sel     <= "00"; -- 12 bit signed immediate
                    regs_in_sel <= "01"; -- PC incremented
                    J <= '1'; -- Set J for unconditional jump
                    B <= '0'; -- Not a branch instruction
                
                when others =>
                    rd_sel      <= (others => '0');
                    rs1_sel     <= (others => '0');
                    rs2_sel     <= (others => '0');
                    funct7      <= (others => '0');
                    funct3 <= (others => '0');
                    op2_sel     <= '0';
                    adder_sp_sel<= '0';
                    imm         <= (others => '0');
                    imm_sel     <= (others => '0');
                    regs_in_sel <= "00"; -- ALU result
            end case;

    end process; 
    branch_out <= (branch_in and B) or J; --branch if conditional and success check, or just unconditional jumps
end architecture RTL;