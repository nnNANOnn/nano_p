----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240047N
-- 
-- Create Date: 05.08.2026 
-- Design Name: 
-- Module Name: TB_HA - Behavioral
-- Project Name: Nanoprocessor
-- Target Devices: Basys 3
-- Tool Versions: 
-- Description: Testbench for Half Adder
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_HA is
end TB_HA;

architecture Behavioral of TB_HA is
    component HA is
        Port ( A : in STD_LOGIC; B : in STD_LOGIC; S : out STD_LOGIC; C : out STD_LOGIC);
    end component;
    
    signal A, B, S, C : STD_LOGIC;
begin
    UUT: HA port map( A => A, B => B, S => S, C => C );
    
    process
    begin
        -- Index Number: 240047N
        -- Binary Representation: 0011 1010 1001 1010 1111
        
        -- TC1: Using bits 1 and 0
        A <= '1'; B <= '1';
        wait for 100 ns;
        
        -- TC2: Using bits 3 and 2
        A <= '1'; B <= '1';
        wait for 100 ns;
        
        -- TC3: Using bits 5 and 4
        A <= '1'; B <= '0';
        wait for 100 ns;
        
        -- TC4: Using bits 7 and 6
        A <= '1'; B <= '0';
        wait for 100 ns;
        
        -- TC5: Using bits 9 and 8
        A <= '0'; B <= '1';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;