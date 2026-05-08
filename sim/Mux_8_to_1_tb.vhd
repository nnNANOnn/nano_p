----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240045G
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_Mux_8_to_1 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Mux_8_to_1 is
end TB_Mux_8_to_1;

architecture Behavioral of TB_Mux_8_to_1 is
    component Mux_8_1 is
        Port ( S : in STD_LOGIC_VECTOR(2 downto 0); D : in STD_LOGIC_VECTOR(7 downto 0); EN : in STD_LOGIC; Y : out STD_LOGIC);
    end component;
    signal S : STD_LOGIC_VECTOR(2 downto 0); signal D : STD_LOGIC_VECTOR(7 downto 0); signal EN, Y : STD_LOGIC;
begin
    UUT: Mux_8_1 port map( S => S, D => D, EN => EN, Y => Y );
    process
    begin
        -- Index Number: 240045G
        -- Binary Representation: 0011 1010 1001 1010 1101
        
        -- TC1: S=bits(2..0), D=bits(10..3), EN=bit(11)
        S <= "101"; D <= "01101011"; EN <= '1';
        wait for 100 ns;
        
        -- TC2: S=bits(14..12), D=bits(9..2), EN=bit(10)
        S <= "010"; D <= "10100110"; EN <= '1';
        wait for 100 ns;
        
        -- TC3: S=bits(5..3), D=bits(18..11), EN=bit(19)
        S <= "101"; D <= "00111010"; EN <= '0';
        wait for 100 ns;
        
        -- TC4: S=bits(8..6), D=bits(15..8), EN=bit(7)
        S <= "100"; D <= "10101001"; EN <= '1';
        wait for 100 ns;
        
        -- TC5: S=bits(11..9), D=bits(19..12), EN=bit(8)
        S <= "100"; D <= "00111010"; EN <= '1';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;