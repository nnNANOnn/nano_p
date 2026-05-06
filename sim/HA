
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_HA is
--  Port ( );
end TB_HA;

architecture Behavioral of TB_HA is

COMPONENT HA
    PORT(
        A,B : in std_logic;
        S,C : out std_logic
    );
END COMPONENT;

SIGNAL a,b,s,c: std_logic;
        

begin
UUT: HA PORT MAP(
    A => a,
    B => b,
    C => c,
    S => s
    );
process 
BEGIN 
    a <= '0';
    b <= '0';
    
    WAIT FOR 100 ns;
    a <= '1';
    
    WAIT FOR 100 ns;
    b <= '1';
    
    WAIT FOR 100 ns;
    a <= '0';
    
    WAIT;
END PROCESS;
end Behavioral;
