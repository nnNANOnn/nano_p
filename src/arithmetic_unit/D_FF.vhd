----------------------------------------------------------------------------------
-- Module : D_FF
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Single-bit D flip-flop with synchronous reset and clock-enable.
--   * Res = '1' on a rising edge clears Q to '0' (Qbar to '1').
--   * Otherwise, when En = '1', Q follows D.
--   * When En = '0', Q holds.
-- The only stateful primitive in the entire project.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity D_FF is
    Port (
        D    : in  STD_LOGIC;
        Res  : in  STD_LOGIC;
        Clk  : in  STD_LOGIC;
        En   : in  STD_LOGIC;
        Q    : out STD_LOGIC;
        Qbar : out STD_LOGIC
    );
end D_FF;

architecture Behavioral of D_FF is
begin
    process (Clk)
    begin
        if rising_edge(Clk) then
            if Res = '1' then
                Q    <= '0';
                Qbar <= '1';
            elsif En = '1' then
                Q    <= D;
                Qbar <= not D;
            end if;
        end if;
    end process;
end Behavioral;
