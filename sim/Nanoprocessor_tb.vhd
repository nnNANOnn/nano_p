----------------------------------------------------------------------------------
-- Module : Nanoprocessor_tb
-- Project: Nanoprocessor (Lab 9-10, CS1050)
--
-- End-to-end testbench for the top-level nanoprocessor.  Drives a fast
-- "100 MHz" clock and the reset pushbutton, lets the slow-clock divider
-- generate the slow clock internally, and observes R7 (result),
-- Zero_LED, Carry_LED.
--
-- The DIV_LIMIT generic of the DUT is overridden here to 5, so one
-- slow-clock period is 100 ns of simulation time and the program
-- finishes in ~1.6 us.  No source edits needed.
--
-- Expected outcome of the Step-4 program (sum 1..3):
--   By slow-cycle 12, R7 = "0110" (decimal 6).
--   By slow-cycle 14, the PC is parked at address 6 in a self-loop
--   and R7 stays at "0110" forever.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Nanoprocessor_tb is
end Nanoprocessor_tb;

architecture Behavioral of Nanoprocessor_tb is

    -- DUT ports
    signal Clk_100MHz : STD_LOGIC := '0';
    signal Reset_Btn  : STD_LOGIC := '1';

    signal Result_LED : STD_LOGIC_VECTOR(3 downto 0);
    signal Zero_LED   : STD_LOGIC;
    signal Carry_LED  : STD_LOGIC;
    signal Cathodes   : STD_LOGIC_VECTOR(6 downto 0);
    signal Anodes     : STD_LOGIC_VECTOR(3 downto 0);

    -- 10 ns period -> 100 MHz
    constant CLK_PERIOD : time := 10 ns;

begin

    -- DUT.  Override DIV_LIMIT for fast simulation: each slow-clock
    -- half-period takes 5 input cycles = 50 ns, so a full period is 100 ns.
    UUT : entity work.Nanoprocessor
        generic map (
            DIV_LIMIT => 5
        )
        port map (
            Clk_100MHz => Clk_100MHz,
            Reset_Btn  => Reset_Btn,
            Result_LED => Result_LED,
            Zero_LED   => Zero_LED,
            Carry_LED  => Carry_LED,
            Cathodes   => Cathodes,
            Anodes     => Anodes
        );

    -- 100 MHz clock generator
    clk_gen : process
    begin
        Clk_100MHz <= '0';
        wait for CLK_PERIOD / 2;
        Clk_100MHz <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus: hold reset for a few cycles, then release and let the
    -- program run.  Self-check at the end verifies R7 = "0110".
    stim : process
    begin
        Reset_Btn <= '1';
        wait for 5 * CLK_PERIOD;
        Reset_Btn <= '0';

        -- 5 us is plenty (program finishes around 1.6 us with DIV_LIMIT=5).
        wait for 5 us;

        assert Result_LED = "0110"
            report "FAIL: R7 expected 0110 (=6), got something else."
            severity failure;

        report "PASS: nanoprocessor computed sum 1+2+3 = 6 correctly."
            severity note;

        wait;
    end process;

end Behavioral;
