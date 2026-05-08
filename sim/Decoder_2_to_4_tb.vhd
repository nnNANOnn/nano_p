----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240043A
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_Decoder_2_to_4 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Decoder_2_to_4 is
end TB_Decoder_2_to_4;

architecture Behavioral of TB_Decoder_2_to_4 is
    component Decoder_2_to_4 is
        Port ( I : in STD_LOGIC_VECTOR(1 downto 0); EN : in STD_LOGIC; Y : out STD_LOGIC_VECTOR(3 downto 0));
    end component;
    signal I : STD_LOGIC_VECTOR(1 downto 0); signal EN : STD_LOGIC; signal Y : STD_LOGIC_VECTOR(3 downto 0);
begin
    UUT: Decoder_2_to_4 port map( I => I, EN => EN, Y => Y );
    process
    begin
        -- Index Number: 240043A
        -- Binary Representation: 0011 1010 1001 1010 1011
        
        -- TC1: I=bits(1..0), EN=bit(2)
        I <= "11"; EN <= '0';
        wait for 100 ns;
        
        -- TC2: I=bits(4..3), EN=bit(5)
        I <= "01"; EN <= '1';
        wait for 100 ns;
        
        -- TC3: I=bits(7..6), EN=bit(8)
        I <= "10"; EN <= '0';
        wait for 100 ns;
        
        -- TC4: I=bits(10..9), EN=bit(11)
        I <= "10"; EN <= '1';
        wait for 100 ns;
        
        -- TC5: I=bits(13..12), EN=bit(14)
        I <= "01"; EN <= '0';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;