library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_4_RCA is
-- Testbench has no ports
end TB_4_RCA;

architecture Behavioral of TB_4_RCA is

    -- 1. Component declaration MUST match your RCA_4 entity exactly
    COMPONENT RCA_4 
    PORT(
        A : IN STD_LOGIC_VECTOR(3 downto 0);
        B : IN STD_LOGIC_VECTOR(3 downto 0);
        C_in : IN STD_LOGIC;
        S : OUT STD_LOGIC_VECTOR(3 downto 0);
        C_out : OUT STD_LOGIC;
        C_in_last : OUT STD_LOGIC -- Added to match your RCA_4 port
    ); 
    END COMPONENT; 

    -- 2. Use Vectors for signals to match the component
    SIGNAL A : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    SIGNAL B : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    SIGNAL S : STD_LOGIC_VECTOR(3 downto 0);
    SIGNAL C_in, C_out, C_in_last : STD_LOGIC := '0';

begin

    -- 3. Simplified Port Map
    UUT: RCA_4 
    PORT MAP( 
        A => A, 
        B => B, 
        C_in => C_in, 
        S => S, 
        C_out => C_out,
        C_in_last => C_in_last
    ); 

    -- 4. Stimulus Process (Converted your bit-by-bit values to Vectors)
    PROCESS
    BEGIN
        -- Test 1: A="1010" (A3=1, A2=0, A1=1, A0=0), B="0100"
        A <= "1010"; B <= "0100"; C_in <= '0';
        WAIT FOR 100 ns; 
        
        -- Test 2: A="0011", B="0101"
        A <= "0011"; B <= "0101"; C_in <= '0';
        WAIT FOR 100 ns; 

        -- Test 3: A="1010", B="1101"
        A <= "1010"; B <= "1101"; C_in <= '0';
        WAIT FOR 100 ns; 

        -- Test 4: A="1110", B="1111"
        A <= "1110"; B <= "1111"; C_in <= '0';
        WAIT FOR 100 ns; 

        -- Test 5: All 1s test
        A <= "1111"; B <= "1111"; C_in <= '0';
        WAIT FOR 100 ns; 

        WAIT; -- Stops simulation
    END PROCESS;

end Behavioral;
