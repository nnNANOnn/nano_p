----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240045G
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_Mux_2_4 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Mux_2_4 is
end TB_Mux_2_4;

architecture Behavioral of TB_Mux_2_4 is
    component Mux_2_4 is
        Port ( S : in STD_LOGIC; D0, D1 : in STD_LOGIC_VECTOR(3 downto 0); Y : out STD_LOGIC_VECTOR(3 downto 0));
    end component;
    signal S : STD_LOGIC; signal D0, D1, Y : STD_LOGIC_VECTOR(3 downto 0);
begin
    UUT: Mux_2_4 port map( S => S, D0 => D0, D1 => D1, Y => Y );
    process
    begin
        -- Index Number: 240045G
        -- Binary Representation: 0011 1010 1001 1010 1101
        
        -- TC1: S=bit(0), D0=bits(4..1), D1=bits(8..5)
        S <= '1'; D0 <= "0110"; D1 <= "0101";
        wait for 100 ns;
        
        -- TC2: S=bit(9), D0=bits(13..10), D1=bits(17..14)
        S <= '0'; D0 <= "0110"; D1 <= "1010";
        wait for 100 ns;
        
        -- TC3: S=bit(18), D0=bits(3..0), D1=bits(7..4)
        S <= '0'; D0 <= "1101"; D1 <= "1010";
        wait for 100 ns;
        
        -- TC4: S=bit(8), D0=bits(12..9), D1=bits(16..13)
        S <= '1'; D0 <= "0100"; D1 <= "0101";
        wait for 100 ns;
        
        -- TC5: S=bit(17), D0={bit(2..0), bit(19)}, D1=bits(6..3)
        S <= '1'; D0 <= "1010"; D1 <= "0101";
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;