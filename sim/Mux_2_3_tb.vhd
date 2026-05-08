----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240045G
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_Mux_2_3 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Mux_2_3 is
end TB_Mux_2_3;

architecture Behavioral of TB_Mux_2_3 is
    component Mux_2_3 is
        Port ( S : in STD_LOGIC; D0, D1 : in STD_LOGIC_VECTOR(2 downto 0); Y : out STD_LOGIC_VECTOR(2 downto 0));
    end component;
    signal S : STD_LOGIC; signal D0, D1, Y : STD_LOGIC_VECTOR(2 downto 0);
begin
    UUT: Mux_2_3 port map( S => S, D0 => D0, D1 => D1, Y => Y );
    process
    begin
        -- Index Number: 240045G
        -- Binary Representation: 0011 1010 1001 1010 1101
        
        -- TC1: S=bit(0), D0=bits(3..1), D1=bits(6..4)
        S <= '1'; D0 <= "110"; D1 <= "010";
        wait for 100 ns;
        
        -- TC2: S=bit(7), D0=bits(10..8), D1=bits(13..11)
        S <= '1'; D0 <= "001"; D1 <= "101";
        wait for 100 ns;
        
        -- TC3: S=bit(14), D0=bits(17..15), D1=bits(2..0)
        S <= '0'; D0 <= "101"; D1 <= "101";
        wait for 100 ns;
        
        -- TC4: S=bit(3), D0=bits(6..4), D1=bits(9..7)
        S <= '1'; D0 <= "010"; D1 <= "011";
        wait for 100 ns;
        
        -- TC5: S=bit(10), D0=bits(13..11), D1=bits(16..14)
        S <= '0'; D0 <= "101"; D1 <= "010";
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;