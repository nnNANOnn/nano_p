----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240043A
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_Decoder_3_to_8 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Decoder_3_to_8 is
end TB_Decoder_3_to_8;

architecture Behavioral of TB_Decoder_3_to_8 is
    component Decoder_3_to_8 is
        Port ( I : in STD_LOGIC_VECTOR(2 downto 0); EN : in STD_LOGIC; Y : out STD_LOGIC_VECTOR(7 downto 0));
    end component;
    signal I : STD_LOGIC_VECTOR(2 downto 0); signal EN : STD_LOGIC; signal Y : STD_LOGIC_VECTOR(7 downto 0);
begin
    UUT: Decoder_3_to_8 port map( I => I, EN => EN, Y => Y );
    process
    begin
        -- Index Number: 240043A
        -- Binary Representation: 0011 1010 1001 1010 1011
        
        -- TC1: I=bits(2..0), EN=bit(3)
        I <= "011"; EN <= '1';
        wait for 100 ns;
        
        -- TC2: I=bits(6..4), EN=bit(7)
        I <= "010"; EN <= '1';
        wait for 100 ns;
        
        -- TC3: I=bits(10..8), EN=bit(11)
        I <= "001"; EN <= '1';
        wait for 100 ns;
        
        -- TC4: I=bits(14..12), EN=bit(15)
        I <= "010"; EN <= '1';
        wait for 100 ns;
        
        -- TC5: I=bits(18..16), EN=bit(19)
        I <= "011"; EN <= '0';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;