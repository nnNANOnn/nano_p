----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240047N
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_AddSub_4 - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_AddSub_4 is
end TB_AddSub_4;

architecture Behavioral of TB_AddSub_4 is
    component Add_Sub_4_bit is
        Port ( A_AS, B_AS : in STD_LOGIC_VECTOR(3 downto 0); CTRL : in STD_LOGIC; S_AS : out STD_LOGIC_VECTOR(3 downto 0); Zero, OverFlow, Carry_Out : out STD_LOGIC);
    end component;
    signal A_AS, B_AS, S_AS : STD_LOGIC_VECTOR(3 downto 0); signal CTRL, Zero, OverFlow, Carry_Out : STD_LOGIC;
begin
    UUT: Add_Sub_4_bit port map( A_AS => A_AS, B_AS => B_AS, CTRL => CTRL, S_AS => S_AS, Zero => Zero, OverFlow => OverFlow, Carry_Out => Carry_Out );
    process
    begin
        -- Index Number: 240047N
        -- Binary Representation: 0011 1010 1001 1010 1111
        
        -- TC1: A_AS=bits(3..0), B_AS=bits(7..4), CTRL=bit(8)
        A_AS <= "1111"; B_AS <= "1010"; CTRL <= '1';
        wait for 100 ns;
        
        -- TC2: A_AS=bits(11..8), B_AS=bits(15..12), CTRL=bit(16)
        A_AS <= "1001"; B_AS <= "1010"; CTRL <= '0';
        wait for 100 ns;
        
        -- TC3: A_AS=bits(19..16), B_AS=bits(3..0), CTRL=bit(4)
        A_AS <= "0011"; B_AS <= "1111"; CTRL <= '0';
        wait for 100 ns;
        
        -- TC4: A_AS=bits(7..4), B_AS=bits(11..8), CTRL=bit(12)
        A_AS <= "1010"; B_AS <= "1001"; CTRL <= '0';
        wait for 100 ns;
        
        -- TC5: A_AS=bits(15..12), B_AS=bits(19..16), CTRL=bit(0)
        A_AS <= "1010"; B_AS <= "0011"; CTRL <= '1';
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;