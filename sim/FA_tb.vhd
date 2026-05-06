library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TB_FA is
--  Port ( );
end TB_FA;

architecture Behavioral of TB_FA is

COMPONENT FA 
    PORT(
    A,B,C_in : in std_logic;
    S,C_out : out std_logic);
END COMPONENT;

SIGNAL A,B,C_in,S,C_out: std_logic;

begin
UUT: FA PORT MAP(
    A => A,
    B => B,
    C_in => C_in,
    S => S,
    C_out => C_out);
    
PROCESS
BEGIN
    A <= '0';
    B <= '0';
    C_in <= '0';
    
    WAIT FOR 100 ns;
    A <= '1';
    
    WAIT FOR 100 ns;
    B <= '1';
    
    WAIT FOR 100 ns;
    A <= '0';
    
    WAIT FOR 100 ns;
    C_in <= '1';
    
    WAIT FOR 100 ns;
    A <= '1';
    
    WAIT FOR 100 ns;
    B <= '0';
    
    WAIT FOR 100 ns;
    A <= '0';
    
    WAIT;
END PROCESS;

end Behavioral;
