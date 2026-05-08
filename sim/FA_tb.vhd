----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240047N
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_FA - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_FA is
end TB_FA;

architecture Behavioral of TB_FA is
    component FA is
        Port ( A, B, C_in : in STD_LOGIC; S, C_out : out STD_LOGIC);
    end component;
    signal A, B, C_in, S, C_out : STD_LOGIC;
begin
    UUT: FA port map( A => A, B => B, C_in => C_in, S => S, C_out => C_out );
    process
    begin
        -- Index Number: 240047N
        -- Binary Representation: 0011 1010 1001 1010 1111
        
        -- TC1: Using bits 2 downto 0 (111)
        A <= '1'; B <= '1'; C_in <= '1';
        wait for 100 ns;
        
        -- TC2: Using bits 5 downto 3 (011)
        A <= '0'; B <= '1'; C_in <= '1';
        wait for 100 ns;
        
        -- TC3: Using bits 8 downto 6 (010)
        A <= '0'; B <= '1'; C_in <= '0';
        wait for 100 ns;
        
        -- TC4: Using bits 11 downto 9 (100)
        A <= '1'; B <= '0'; C_in <= '0';
        wait for 100 ns;
        
        -- TC5: Using bits 14 downto 12 (010)
        A <= '0'; B <= '1'; C_in <= '0';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;