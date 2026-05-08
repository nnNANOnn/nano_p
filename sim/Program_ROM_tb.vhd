library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.buses.all;

entity Program_ROM_tb is
end Program_ROM_tb;

architecture Behavioral of Program_ROM_tb is
    signal ROM_address : instruction_address := "000";
    signal I           : instruction_bus;
begin
    UUT: entity work.Program_ROM
        port map (ROM_address => ROM_address, I => I);

    stim : process
    begin
        for addr in 0 to 7 loop
            ROM_address <= std_logic_vector(to_unsigned(addr, 3));
            wait for 20 ns;
        end loop;
        wait;
    end process;
end Behavioral;