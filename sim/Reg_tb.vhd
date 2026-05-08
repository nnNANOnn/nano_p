----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240043A
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_Reg - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Reg is
end TB_Reg;

architecture Behavioral of TB_Reg is
    component Reg is
        generic ( N : integer := 4 );
        Port ( D : in STD_LOGIC_VECTOR(N-1 downto 0); Res, En, Clk : in STD_LOGIC; Q : out STD_LOGIC_VECTOR(N-1 downto 0));
    end component;
    signal D, Q : STD_LOGIC_VECTOR(3 downto 0); signal Res, En, Clk : STD_LOGIC := '0';
begin
    UUT: Reg generic map(N=>4) port map( D => D, Res => Res, En => En, Clk => Clk, Q => Q );
    
    process begin Clk <= '0'; wait for 10 ns; Clk <= '1'; wait for 10 ns; end process;
    
    process
    begin
        -- Index Number: 240043A
        -- Binary Representation: 0011 1010 1001 1010 1011
        
        -- TC1: D=bits(3..0), Res=bit(4), En=bit(5)
        D <= "1011"; Res <= '0'; En <= '1';
        wait for 40 ns;
        
        -- TC2: D=bits(7..4), Res=bit(8), En=bit(9)
        D <= "1010"; Res <= '0'; En <= '1';
        wait for 40 ns;
        
        -- TC3: D=bits(11..8), Res=bit(12), En=bit(13)
        D <= "1001"; Res <= '0'; En <= '1';
        wait for 40 ns;
        
        -- TC4: D=bits(15..12), Res=bit(16), En=bit(17)
        D <= "1010"; Res <= '1'; En <= '0';
        wait for 40 ns;
        
        -- TC5: D=bits(19..16), Res=bit(0), En=bit(1)
        D <= "0011"; Res <= '1'; En <= '1';
        wait for 40 ns;
        
        wait;
    end process;
end Behavioral;