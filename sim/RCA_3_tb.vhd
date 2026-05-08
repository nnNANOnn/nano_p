----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240047N
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_RCA_3 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_RCA_3 is
end TB_RCA_3;

architecture Behavioral of TB_RCA_3 is
    component RCA_3 is
        Port ( A, B : in STD_LOGIC_VECTOR(2 downto 0); C_in : in STD_LOGIC; S : out STD_LOGIC_VECTOR(2 downto 0); C_out : out STD_LOGIC);
    end component;
    signal A, B : STD_LOGIC_VECTOR(2 downto 0); signal C_in, C_out : STD_LOGIC; signal S : STD_LOGIC_VECTOR(2 downto 0);
begin
    UUT: RCA_3 port map( A => A, B => B, C_in => C_in, S => S, C_out => C_out );
    process
    begin
        -- Index Number: 240047N
        -- Binary Representation: 0011 1010 1001 1010 1111
        
        -- TC1: A=bits(2..0), B=bits(5..3), C_in=bit(6)
        A <= "111"; B <= "011"; C_in <= '0';
        wait for 100 ns;
        
        -- TC2: A=bits(9..7), B=bits(12..10), C_in=bit(13)
        A <= "101"; B <= "010"; C_in <= '1';
        wait for 100 ns;
        
        -- TC3: A=bits(16..14), B=bits(19..17), C_in=bit(0)
        A <= "010"; B <= "001"; C_in <= '1';
        wait for 100 ns;
        
        -- TC4: A=bits(5..3), B=bits(8..6), C_in=bit(9)
        A <= "011"; B <= "010"; C_in <= '1';
        wait for 100 ns;
        
        -- TC5: A=bits(11..9), B=bits(14..12), C_in=bit(15)
        A <= "001"; B <= "010"; C_in <= '0';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;