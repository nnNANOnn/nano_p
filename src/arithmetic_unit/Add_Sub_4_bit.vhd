library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.adders.all;

entity Add_Sub_4_bit is
    Port (
        A_AS     : in  STD_LOGIC_VECTOR(3 downto 0);
        B_AS     : in  STD_LOGIC_VECTOR(3 downto 0);
        CTRL     : in  STD_LOGIC;                       -- '0'=add, '1'=subtract
        S_AS     : out STD_LOGIC_VECTOR(3 downto 0);
        Zero     : out STD_LOGIC;
        OverFlow : out STD_LOGIC;
        Carry_Out: out STD_LOGIC                        -- NEW: For strict lab compliance
    );
end Add_Sub_4_bit;

architecture Behavioral of Add_Sub_4_bit is
    signal B_inter        : STD_LOGIC_VECTOR(3 downto 0);
    signal S_inter        : STD_LOGIC_VECTOR(3 downto 0);
    signal C_out_final    : STD_LOGIC;
    signal C_in_last_bit  : STD_LOGIC;
begin
    B_inter <= B_AS xor (CTRL & CTRL & CTRL & CTRL);
    
    RCA_4_0 : RCA_4
        port map (
            A         => A_AS,
            B         => B_inter,
            C_in      => CTRL,
            S         => S_inter,
            C_out     => C_out_final,
            C_in_last => C_in_last_bit
        );
        
    OverFlow <= C_in_last_bit xor C_out_final;
    Zero <= '1' when S_inter = "0000" else '0';
    S_AS <= S_inter;
    Carry_Out <= C_out_final;                           -- NEW: Wire the actual carry out
end Behavioral;