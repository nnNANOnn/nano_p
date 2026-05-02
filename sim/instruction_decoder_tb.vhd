----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.05.2026 15:49:33
-- Design Name: 
-- Module Name: instruction_decoder_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity instruction_decoder_tb is
-- Test bench has no ports
end instruction_decoder_tb;

architecture Behavioral of instruction_decoder_tb is

    -- Component Declaration for the UUT
    component instruction_decoder
        Port (
            instruction     : in  STD_LOGIC_VECTOR (11 downto 0);
            reg_check_val   : in  STD_LOGIC_VECTOR (3 downto 0);
            reg_en_sel      : out STD_LOGIC_VECTOR (2 downto 0);
            reg_write_en    : out STD_LOGIC;
            load_sel        : out STD_LOGIC;
            imm_val         : out STD_LOGIC_VECTOR (3 downto 0);
            mux_a_sel       : out STD_LOGIC_VECTOR (2 downto 0);
            mux_b_sel       : out STD_LOGIC_VECTOR (2 downto 0);
            add_sub_sel     : out STD_LOGIC;
            jump_flag       : out STD_LOGIC;
            jump_addr       : out STD_LOGIC_VECTOR (2 downto 0)
        );
    end component;

    -- Stimulus Signals
    signal instruction     : STD_LOGIC_VECTOR (11 downto 0) := (others => '0');
    signal reg_check_val   : STD_LOGIC_VECTOR (3 downto 0)  := (others => '0');
    
    -- Output Observation Signals
    signal reg_en_sel      : STD_LOGIC_VECTOR (2 downto 0);
    signal reg_write_en    : STD_LOGIC;
    signal load_sel        : STD_LOGIC;
    signal imm_val         : STD_LOGIC_VECTOR (3 downto 0);
    signal mux_a_sel       : STD_LOGIC_VECTOR (2 downto 0);
    signal mux_b_sel       : STD_LOGIC_VECTOR (2 downto 0);
    signal add_sub_sel     : STD_LOGIC;
    signal jump_flag       : STD_LOGIC;
    signal jump_addr       : STD_LOGIC_VECTOR (2 downto 0);

begin

    -- Instantiate the UUT
    uut: instruction_decoder Port Map (
          instruction   => instruction,
          reg_check_val => reg_check_val,
          reg_en_sel    => reg_en_sel,
          reg_write_en  => reg_write_en,
          load_sel      => load_sel,
          imm_val       => imm_val,
          mux_a_sel     => mux_a_sel,
          mux_b_sel     => mux_b_sel,
          add_sub_sel   => add_sub_sel,
          jump_flag     => jump_flag,
          jump_addr     => jump_addr
        );

    -- Stimulus process
    stim_proc: process
    begin		
        -- Initial Wait
        wait for 100 ns;

        ------------------------------------------------------------
        -- Test Case 1: MOVI R2, 12 (Machine Code: 10 010 000 1100)[cite: 1]
        ------------------------------------------------------------
        instruction <= "100100001100"; 
        wait for 100 ns;
        -- Expected Outcomes: 
        -- load_sel = '1'
        -- imm_val = "1100"
        -- reg_en_sel = "010"
        -- reg_write_en = '1'

        ------------------------------------------------------------
        -- Test Case 2: ADD R1, R2 (Machine Code: 00 001 010 0000)[cite: 1]
        ------------------------------------------------------------
        instruction <= "000010100000";
        wait for 100 ns;
        -- Expected Outcomes: 
        -- load_sel = '0'
        -- add_sub_sel = '0'
        -- mux_a_sel = "001"
        -- mux_b_sel = "010"

        ------------------------------------------------------------
        -- Test Case 3: NEG R3 (Machine Code: 01 011 000 0000)[cite: 1]
        ------------------------------------------------------------
        instruction <= "010110000000";
        wait for 100 ns;
        -- Expected Outcomes: 
        -- add_sub_sel = '1'
        -- mux_a_sel = "000" (Hardwired R0)[cite: 1]
        -- mux_b_sel = "011"

        ------------------------------------------------------------
        -- Test Case 4: JZR R1, 5 (Machine Code: 11 001 000 0101)[cite: 1]
        ------------------------------------------------------------
        instruction <= "110010000101"; 
        
        -- Subcase A: R1 value is NOT zero
        reg_check_val <= "1010"; 
        wait for 100 ns;
        -- Expected Outcomes: jump_flag = '0', jump_addr = "101"

        -- Subcase B: R1 value IS zero
        reg_check_val <= "0000"; 
        wait for 100 ns;
        -- Expected Outcomes: jump_flag = '1', jump_addr = "101"

        -- Stop simulation
        wait;
    end process;

end Behavioral;
