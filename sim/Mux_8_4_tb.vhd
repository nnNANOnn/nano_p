----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240045G
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_MUX_8_4 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.buses.all;

entity TB_MUX_8_4 is
end TB_MUX_8_4;

architecture Behavioral of TB_MUX_8_4 is
    component MUX_8_4 is
        Port ( S : in STD_LOGIC_VECTOR(2 downto 0); D : in data_buses; EN : in STD_LOGIC; Y : out STD_LOGIC_VECTOR(3 downto 0));
    end component;
    signal S : STD_LOGIC_VECTOR(2 downto 0); signal D : data_buses := (others => "0000"); signal EN : STD_LOGIC; signal Y : STD_LOGIC_VECTOR(3 downto 0);
begin
    UUT: MUX_8_4 port map( S => S, D => D, EN => EN, Y => Y );
    process
    begin
        D(0) <= "0000"; D(1) <= "0001"; D(2) <= "0010"; D(3) <= "0011";
        D(4) <= "0100"; D(5) <= "0101"; D(6) <= "0110"; D(7) <= "0111";

        -- Index Number: 240045G
        -- Binary Representation: 0011 1010 1001 1010 1101
        
        -- TC1: S=bits(2..0), EN=bit(3)
        S <= "101"; EN <= '1';
        wait for 100 ns;
        
        -- TC2: S=bits(6..4), EN=bit(7)
        S <= "010"; EN <= '1';
        wait for 100 ns;
        
        -- TC3: S=bits(10..8), EN=bit(11)
        S <= "001"; EN <= '1';
        wait for 100 ns;
        
        -- TC4: S=bits(14..12), EN=bit(15)
        S <= "010"; EN <= '1';
        wait for 100 ns;
        
        -- TC5: S=bits(18..16), EN=bit(19)
        S <= "011"; EN <= '0';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;