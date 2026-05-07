----------------------------------------------------------------------------------
-- Module : Clock_Divider
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- Divides the Basys 3 board clock (100 MHz) down to a "slow clock"
-- whose period is approximately 2 * DIV_LIMIT / 100 000 000 seconds.
-- Default DIV_LIMIT = 100_000_000 yields a 2-second slow-clock period
-- (1 sec high, 1 sec low) -- the lab handout asks for "2 or 3 seconds
-- per tick".
--
-- The output Slow_Clk is intended to drive the rising-edge inputs of
-- the Program Counter and Register Bank only.  Combinational blocks
-- are clockless and run at full speed.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Clock_Divider is
    generic (
        DIV_LIMIT : integer := 100_000_000   -- 1 sec @ 100 MHz -> 2 sec period
    );
    Port (
        Clk_in   : in  STD_LOGIC;            -- 100 MHz board clock
        Res      : in  STD_LOGIC;            -- async reset (active high)
        Slow_Clk : out STD_LOGIC
    );
end Clock_Divider;

architecture Behavioral of Clock_Divider is
    -- 28 bits accommodates DIV_LIMIT up to 2^28 - 1 = 268_435_455
    -- (i.e. up to ~5.36 second slow-clock periods at 100 MHz).
    signal counter : unsigned(27 downto 0) := (others => '0');
    signal toggle  : STD_LOGIC := '0';
begin

    process (Clk_in, Res)
    begin
        if Res = '1' then
            counter <= (others => '0');
            toggle  <= '0';
        elsif rising_edge(Clk_in) then
            if counter = to_unsigned(DIV_LIMIT - 1, counter'length) then
                counter <= (others => '0');
                toggle  <= not toggle;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    Slow_Clk <= toggle;

end Behavioral;
