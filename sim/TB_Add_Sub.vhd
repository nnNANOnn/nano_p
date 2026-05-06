library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Add_Sub is
-- Testbench has no ports
end TB_Add_Sub;

architecture Behavioral of TB_Add_Sub is

    -- 1. Component Declaration for the Unit Under Test (UUT)
    COMPONENT Add_Sub_4_bit
    PORT(
        A_AS : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        B_AS : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        CTRL : IN  STD_LOGIC;
        S_AS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        Zero : OUT STD_LOGIC;
        OverFlow : OUT STD_LOGIC
    );
    END COMPONENT;

    -- 2. Internal Signals to connect to the UUT
    signal A_AS    : STD_LOGIC_VECTOR(3 DOWNTO 0) := (others => '0');
    signal B_AS    : STD_LOGIC_VECTOR(3 DOWNTO 0) := (others => '0');
    signal CTRL    : STD_LOGIC := '0';
    signal S_AS    : STD_LOGIC_VECTOR(3 DOWNTO 0);
    signal Zero    : STD_LOGIC;
    signal OverFlow : STD_LOGIC;

begin

    -- 3. Instantiate the Unit Under Test (UUT)
    uut: Add_Sub_4_bit PORT MAP (
        A_AS => A_AS,
        B_AS => B_AS,
        CTRL => CTRL,
        S_AS => S_AS,
        Zero => Zero,
        OverFlow => OverFlow
    );

    -- 4. Stimulus Process
    stim_proc: process
    begin		
        -- Wait for global reset
        wait for 100 ns;	

        -- CASE 1: Addition (CTRL = '0') -> 5 + 3 = 8
        A_AS <= "0101"; B_AS <= "0011"; CTRL <= '0';
        wait for 100 ns;

        -- CASE 2: Subtraction (CTRL = '1') -> 5 - 3 = 2
        A_AS <= "0101"; B_AS <= "0011"; CTRL <= '1';
        wait for 100 ns;

        -- CASE 3: Zero Flag Test -> 7 - 7 = 0
        A_AS <= "0111"; B_AS <= "0111"; CTRL <= '1';
        wait for 100 ns;

        -- CASE 4: Overflow Test (Signed) -> 7 + 1 = -8 (Error in 4-bit signed)
        -- 0111 + 0001 = 1000. Carry into MSB is 1, Carry out is 0. 1 XOR 0 = 1 (Overflow)
        A_AS <= "0111"; B_AS <= "0001"; CTRL <= '0';
        wait for 100 ns;

        -- CASE 5: Negative Subtraction -> (-4) - (1) = -5
        -- "1100" - "0001"
        A_AS <= "1100"; B_AS <= "0001"; CTRL <= '1';
        wait for 100 ns;

        wait; -- End of simulation
    end process;

end Behavioral;
