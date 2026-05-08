library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Clock_Divider_tb is
end Clock_Divider_tb;

architecture Behavioral of Clock_Divider_tb is
    signal Clk_in   : STD_LOGIC := '0';
    signal Res      : STD_LOGIC := '0';
    signal Slow_Clk : STD_LOGIC;
begin
    Clk_in <= not Clk_in after 5 ns;

    UUT: entity work.Clock_Divider
        generic map (DIV_LIMIT => 5) -- Small value for fast simulation
        port map (Clk_in => Clk_in, Res => Res, Slow_Clk => Slow_Clk);

    stim : process
    begin
        Res <= '1';
        wait for 20 ns;
        Res <= '0';
        wait for 200 ns;
        wait;
    end process;
end Behavioral;