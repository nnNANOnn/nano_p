library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity D_FF_tb is
-- Testbench has no ports
end D_FF_tb;

architecture Behavioral of D_FF_tb is

    -- 1. Component Declaration
    component D_FF
        Port ( D : in STD_LOGIC;
               Res : in STD_LOGIC;
               Clk : in STD_LOGIC;
               En : in STD_LOGIC;
               Q : out STD_LOGIC;
               Qbar : out STD_LOGIC);
    end component;

    -- 2. Signal Declarations
    signal D    : STD_LOGIC := '0';
    signal Res  : STD_LOGIC := '0';
    signal Clk  : STD_LOGIC := '0';
    signal En   : STD_LOGIC := '0';
    signal Q    : STD_LOGIC;
    signal Qbar : STD_LOGIC;

    -- Clock period definition
    constant clk_period : time := 10 ns;

begin

    -- 3. Instantiate the Unit Under Test (UUT)
    uut: D_FF port map (
        D => D,
        Res => Res,
        Clk => Clk,
        En => En,
        Q => Q,
        Qbar => Qbar
    );

    -- 4. Clock Process (Generates a 100MHz clock)
    clk_process : process
    begin
        Clk <= '0';
        wait for clk_period/2;
        Clk <= '1';
        wait for clk_period/2;
    end process;

    -- 5. Stimulus Process
    stim_proc: process
    begin		
        -- Initial Reset
        Res <= '1';
        wait for 20 ns;
        Res <= '0';
        wait for 10 ns;

        -- Test 1: Data change with Enable OFF (Q should not change)
        En <= '0'; D <= '1';
        wait for 20 ns;

        -- Test 2: Enable ON (Q should become '1' at the next rising edge)
        En <= '1';
        wait for 20 ns;

        -- Test 3: Change D while Enable is ON
        D <= '0';
        wait for 20 ns;

        -- Test 4: Synchronous Reset (Resets Q to '0' on clock edge)
        D <= '1';
        wait for 5 ns;
        Res <= '1';
        wait for 20 ns;
        Res <= '0';

        -- Test 5: Disable Enable and change D (Q should hold last value)
        En <= '0'; D <= '1';
        wait for 20 ns;

        wait; -- Stop simulation
    end process;

end Behavioral;
