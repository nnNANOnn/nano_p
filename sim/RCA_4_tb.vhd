----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240047N
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_RCA_4 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_RCA_4 is
end TB_RCA_4;

architecture Behavioral of TB_RCA_4 is
    component RCA_4 is
        Port ( A, B : in STD_LOGIC_VECTOR(3 downto 0); C_in : in STD_LOGIC; S : out STD_LOGIC_VECTOR(3 downto 0); C_out, C_in_last : out STD_LOGIC);
    end component;
    signal A, B, S : STD_LOGIC_VECTOR(3 downto 0); signal C_in, C_out, C_in_last : STD_LOGIC;
begin
    UUT: RCA_4 port map( A => A, B => B, C_in => C_in, S => S, C_out => C_out, C_in_last => C_in_last );
    process
    begin
        -- Index Number: 240047N
        -- Binary Representation: 0011 1010 1001 1010 1111
        
        -- TC1: A=bits(3..0), B=bits(7..4), C_in=bit(8)
        A <= "1111"; B <= "1010"; C_in <= '1';
        wait for 100 ns;
        
        -- TC2: A=bits(11..8), B=bits(15..12), C_in=bit(16)
        A <= "1001"; B <= "1010"; C_in <= '0';
        wait for 100 ns;
        
        -- TC3: A=bits(19..16), B=bits(3..0), C_in=bit(4)
        A <= "0011"; B <= "1111"; C_in <= '0';
        wait for 100 ns;
        
        -- TC4: A=bits(7..4), B=bits(11..8), C_in=bit(12)
        A <= "1010"; B <= "1001"; C_in <= '0';
        wait for 100 ns;
        
        -- TC5: A=bits(15..12), B=bits(19..16), C_in=bit(0)
        A <= "1010"; B <= "0011"; C_in <= '1';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;