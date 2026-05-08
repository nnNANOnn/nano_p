library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity PC_tb is
end PC_tb;

architecture Behavioral of PC_tb is
    signal Clk    : STD_LOGIC := '0';
    signal Res    : STD_LOGIC := '0';
    signal M_curr : instruction_address;
    signal A_next : instruction_address;
begin
    Clk <= not Clk after 10 ns;

    inc : entity work.PC_Inc port map (A_in => M_curr, A_out => A_next);
    pc  : entity work.PC port map (A => A_next, Res => Res, Clk => Clk, M => M_curr);

    stim : process
    begin
        Res <= '1';
        wait for 25 ns;
        Res <= '0';
        wait for 200 ns;
        Res <= '1';
        wait for 20 ns;
        Res <= '0';
        wait;
    end process;
end Behavioral;