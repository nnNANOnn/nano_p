library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.adders.all;

entity Add_Sub_4_bit is
        Port(A_AS : in STD_LOGIC_VECTOR (3 DOWNTO 0);
         B_AS : in STD_LOGIC_VECTOR (3 DOWNTO 0);
         CTRL : in STD_LOGIC;
         S_AS : out STD_LOGIC_VECTOR(3 DOWNTO 0);
         Zero : out STD_LOGIC;
         OverFlow : out STD_LOGIC);
end Add_Sub_4_bit;

architecture Behavioral of Add_Sub_4_bit is

SIGNAL B_inter, S_inter: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL C_out_final:STD_LOGIC;
SIGNAL C_in_last_bit:STD_LOGIC;

begin
  B_inter <=B_AS xor ( CTRL & CTRL & CTRL & CTRL);[cite:1]
  RCA_4_0 : RCA_4
    port map(
        A => A_AS,
        B => B_inter,
        C_in => CTRL,
        S => S_inter,
        C_out => C_out_final,
        C_in_last=>C_in_last_bit);

 OverFlow <= C_in_last_bit XOR C_out_final;[cite:1]
 Zero <= '1' when S_inter="0000" else '0';[cite:1]

  S_AS <= S_inter;

end Behavioral;
