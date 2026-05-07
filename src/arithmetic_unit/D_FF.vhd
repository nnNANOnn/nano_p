----------------------------------------------------------------------------------
-- Module : D_FF
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Single-bit D flip-flop with asynchronous active-high reset and a
-- clock-enable.
--
--   * Res = '1' (asynchronous): clears Q to '0' and Qbar to '1'
--     immediately, regardless of the clock.
--   * On the rising edge of Clk, with Res = '0' and En = '1', Q latches D.
--   * When En = '0' (and Res = '0'), Q holds.
--
-- WHY ASYNC RESET?
-- The Basys 3 reset pushbutton can be released at any time relative to
-- the slow clock (which has a 2-second period in hardware).  With a
-- synchronous reset, a momentary press could be released between two
-- slow-clock edges and never actually reset anything.  Async reset
-- guarantees that the moment Res rises, every flip-flop in the design
-- clears -- including the PC, so the program restarts at address 0.
--
-- This is the only stateful primitive in the entire project.
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
    -- Added Res to the sensitivity list for asynchronous behavior
    process (Clk, Res)
    begin
        -- Asynchronous reset check happens independently of the clock
        if Res = '1' then
            Q    <= '0';
            Qbar <= '1';
        -- Synchronous logic follows
        elsif rising_edge(Clk) then
            if En = '1' then
                Q    <= D;
                Qbar <= not D;
            end if;
        end if;
    end process;
end Behavioral;
