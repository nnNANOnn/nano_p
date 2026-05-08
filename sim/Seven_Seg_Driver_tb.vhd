library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Seven_Seg_Driver_tb is
end Seven_Seg_Driver_tb;

architecture Behavioral of Seven_Seg_Driver_tb is
    signal Value    : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal Cathodes : STD_LOGIC_VECTOR(6 downto 0);
    signal Anodes   : STD_LOGIC_VECTOR(3 downto 0);
begin
    UUT: entity work.Seven_Seg_Driver
        port map (Value => Value, Cathodes => Cathodes, Anodes => Anodes);

    stim : process
    begin
        for i in 0 to 15 loop
            Value <= std_logic_vector(to_unsigned(i, 4));
            wait for 10 ns;
        end loop;
        wait;
    end process;
end Behavioral;