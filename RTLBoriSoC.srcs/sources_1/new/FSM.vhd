--This FSM is supposed to keep the cpu state
--We have
--Insruction fetch if, ready
--Decode instruction, also means sending all the right signals
--Fetch the right memory, either store or registers, we cant use wait statemetns, how do we know when the data is ready, i guess it will only be assigned once so the sensitiviy list will pick it up rigt
--Decode the instruction, send the right signals to the alu and PC
--How do we wait for computation, we assume it takes from the rising to the falling edge for the signals to propagage
    --With this architecture the LOAD(STORE) insr are gonna need 2 cycles, because
        -- Rising edge to fetch the address operans
        -- Process target address and proceed to update addr sel signals
        -- On falling edge we set regisers to read 
--On the falling edge we save all of the inputs that have to be saved, ALSO PC
--Back to fetch instruction
--New idea, write buffer, STORE does not write to memory but to a buffer that holds it unitl the next fetch
--The next instruct actually data fetch needs to check this write buffer for a hit
--but this thing has only 2 states which are falling edge and then rising edge

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity FSM is
    port(
        clk: in std_logic;
        rst: in std_logic; -- Reset signal
        mem_en : out std_logic := '0'; -- Memory enable signal for write operation
        reg_en : out std_logic := '0'; -- Register enable signal for write operation
        decoded_en : out std_logic := '0'; -- Decoded enable signal for write operation
        PC_en : out std_logic := '0'; -- PC enable signasl for write operation
        instr_en : out std_logic := '0'; -- Instruction enable signal for write operation
        write_buffer_en : out std_logic := '0'; -- Write buffer enable signal for write operation
        RW_op : in std_logic -- Read/Write operation signal
    );
end entity;

architecture RTL of FSM is

    -- States: 0 = Init, 1 = Fetch, 2 = Decode, 3 = Execute, 4 = RW/Fetch, 5 = RW Decode
    signal state: integer range 0 to 5 := 0;
    signal next_state: integer range 0 to 5;

    signal mem_en_r, reg_en_r, PC_en_r, instr_en_r, write_buffer_en_r: std_logic := '0';

begin

    mem_en          <= mem_en_r;
    reg_en          <= reg_en_r;
    PC_en           <= PC_en_r;
    instr_en        <= instr_en_r;
    write_buffer_en <= write_buffer_en_r;

    -- Combinational next state logic
    process(state, RW_op)
    begin
        case state is
            when 0 => -- Init state
                next_state <= 1;
            when 1 => -- Fetch instruction
                next_state <= 2;
            when 2 => -- Decode
                next_state <= 3;
            when 3 => -- Execute
                if RW_op = '1' then
                    next_state <= 4; -- Go to RW/Fetch if memory op
                else
                    next_state <= 1; -- Otherwise, back to Fetch
                end if;
            when 4 => -- RW/Fetch (memory access + fetch next instr)
                next_state <= 5; -- Go to RW Decode
            when 5 => -- RW Decode (decode for instr after memory op)
                next_state <= 3; -- Go to Execute for next instruction
            when others =>
                next_state <= 0;
        end case;
    end process;

    -- Clocked process: state register and registered outputs
    process(clk, rst)
    begin
        if rst = '1' then
            state <= 0;
            mem_en_r          <= '0';
            reg_en_r          <= '0';
            PC_en_r           <= '0';
            instr_en_r        <= '0';
            write_buffer_en_r <= '0';
        elsif rising_edge(clk) then
            state <= next_state;

            case next_state is
                when 1 => -- Fetch instruction
                    mem_en_r          <= '0';
                    reg_en_r          <= '0';
                    decoded_en        <= '0';
                    PC_en_r           <= '0';
                    instr_en_r        <= '1';
                    write_buffer_en_r <= '0';
                when 2 => -- Decode
                    mem_en_r          <= '0';
                    reg_en_r          <= '0';
                    decoded_en        <= '1'; -- Latch decoded values
                    PC_en_r           <= '0';
                    instr_en_r        <= '0';
                    write_buffer_en_r <= '0';
                when 3 => -- Execute
                    mem_en_r          <= '0';
                    reg_en_r          <= '1';
                    decoded_en        <= '0';
                    PC_en_r           <= '1';
                    instr_en_r        <= '0';
                    write_buffer_en_r <= '0';
                when 4 => -- RW/Fetch (memory access + fetch next instr)
                    mem_en_r          <= '1';
                    reg_en_r          <= '1'; -- or '0' for store, '1' for load, this is taken care of by the execute logic of the last instruction
                    decoded_en        <= '0';
                    PC_en_r           <= '0';
                    instr_en_r        <= '1';
                    write_buffer_en_r <= '0';
                when 5 => -- RW Decode (decode for instr after memory op)
                    mem_en_r          <= '1'; -- Keep memory enabled
                    reg_en_r          <= '1'; -- Enable register write for load
                    decoded_en        <= '1'; -- Latch decoded values for next instruction
                    PC_en_r           <= '0';
                    instr_en_r        <= '0';
                    write_buffer_en_r <= '0';
                when others =>
                    mem_en_r          <= '0';
                    reg_en_r          <= '0';
                    decoded_en        <= '0';
                    PC_en_r           <= '0';
                    instr_en_r        <= '0';
                    write_buffer_en_r <= '0';
            end case;
        end if;
    end process;

end architecture RTL;