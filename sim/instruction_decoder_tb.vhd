----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 240005K
-- 
-- Create Date: 05.08.2026 
-- Module Name: TB_instruction_decoder - Behavioral
-- Project Name: Nanoprocessor
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_instruction_decoder is
end TB_instruction_decoder;

architecture Behavioral of TB_instruction_decoder is
    component instruction_decoder is
        Port ( instruction : in STD_LOGIC_VECTOR (11 downto 0); reg_check_val : in STD_LOGIC_VECTOR (3 downto 0);
               reg_en_sel, mux_a_sel, mux_b_sel, jump_addr : out STD_LOGIC_VECTOR (2 downto 0);
               reg_write_en, load_sel, add_sub_sel, jump_flag : out STD_LOGIC; imm_val : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    signal instruction : STD_LOGIC_VECTOR(11 downto 0); signal reg_check_val, imm_val : STD_LOGIC_VECTOR(3 downto 0);
    signal reg_en_sel, mux_a_sel, mux_b_sel, jump_addr : STD_LOGIC_VECTOR(2 downto 0); signal reg_write_en, load_sel, add_sub_sel, jump_flag : STD_LOGIC;
begin
    UUT: instruction_decoder port map( instruction => instruction, reg_check_val => reg_check_val, reg_en_sel => reg_en_sel, reg_write_en => reg_write_en, load_sel => load_sel, imm_val => imm_val, mux_a_sel => mux_a_sel, mux_b_sel => mux_b_sel, add_sub_sel => add_sub_sel, jump_flag => jump_flag, jump_addr => jump_addr );
    process
    begin
        -- Index Number: 240005K
        -- Binary Representation: 0011 1010 1001 1000 0101
        
        -- TC1: instruction=bits(11..0), reg_check_val=bits(15..12)
        instruction <= "101010011000"; reg_check_val <= "1010";
        wait for 100 ns;
        
        -- TC2: instruction=bits(15..4), reg_check_val=bits(19..16)
        instruction <= "101010011000"; reg_check_val <= "0011";
        wait for 100 ns;
        
        -- TC3: instruction=bits(19..8), reg_check_val=bits(3..0)
        instruction <= "001110101001"; reg_check_val <= "0101";
        wait for 100 ns;
        
        -- TC4: instruction={bits(3..0), bits(19..12)}, reg_check_val=bits(7..4)
        instruction <= "010100111010"; reg_check_val <= "1000";
        wait for 100 ns;
        
        -- TC5: instruction={bits(7..0), bits(19..16)}, reg_check_val=bits(11..8)
        instruction <= "100001010011"; reg_check_val <= "1001";
        wait for 100 ns;
        
        wait;
    end process;
end Behavioral;