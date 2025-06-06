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

entity FSM
    port(
        clk: in std_logic;
        instr_fetch_accept: out std_logic; --this goes to the en, of the instr_reg, also rising edge
        write_buffer_to_mem: out std_logic; -- actually this only happends on the rising edge so we do not care    

    );
end entity;


architecture RTL of FSM is
   signal 
    begin
    process(clk)
        if(rising_edge(clk)) then
            --Fetch and Compute

            --instr_fetch_acc
            --write_buffer_to_mem
        elsif(falling_edge(clk)) then
            --write to reg
            --write to buffer
            --write to pc
        end if;
    end process;

end architecture RTL;