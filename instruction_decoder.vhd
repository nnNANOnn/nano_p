----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01.05.2026 14:40:14
-- Design Name: 
-- Module Name: instruction_decoder - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



entity instruction_decoder is
    Port (
        -- Inputs from Program ROM and Datapath
        instruction     : in  STD_LOGIC_VECTOR (11 downto 0); -- 12-bit instruction bus
        reg_check_val   : in  STD_LOGIC_VECTOR (3 downto 0);  -- Register check for jump bus[cite: 1]

        -- Outputs to Datapath Components
        reg_en_sel      : out STD_LOGIC_VECTOR (2 downto 0);  -- Register enable to 3-to-8 decoder[cite: 1]
        reg_write_en    : out STD_LOGIC;                      -- Custom signal to trigger write
        load_sel        : out STD_LOGIC;                      -- Load select for 2-way 4-bit Mux[cite: 1]
        imm_val         : out STD_LOGIC_VECTOR (3 downto 0);  -- 4-bit Immediate value[cite: 1]
        mux_a_sel       : out STD_LOGIC_VECTOR (2 downto 0);  -- Register select (8-way Mux A)[cite: 1]
        mux_b_sel       : out STD_LOGIC_VECTOR (2 downto 0);  -- Register select (8-way Mux B)[cite: 1]
        add_sub_sel     : out STD_LOGIC;                      -- Add/Sub select for ALU[cite: 1]
        jump_flag       : out STD_LOGIC;                      -- Jump Flag to PC Mux[cite: 1]
        jump_addr       : out STD_LOGIC_VECTOR (2 downto 0)   -- Address to jump (+1 or d)[cite: 1]
    );
end instruction_decoder;

architecture Behavioral of instruction_decoder is
begin

    process(instruction, reg_check_val)
        variable opcode : std_logic_vector(1 downto 0);
    begin
        -- Extract the primary 2-bit opcode[cite: 1]
        opcode := instruction(11 downto 10);

        -- 🔹 DEFAULT ASSIGNMENTS (Prevents Latches and sets safe idle states)
        reg_en_sel   <= instruction(9 downto 7); -- Default targets R or Ra[cite: 1]
        reg_write_en <= '0';
        load_sel     <= '0';
        imm_val      <= instruction(3 downto 0); -- Extract dddd bits[cite: 1]
        mux_a_sel    <= instruction(9 downto 7); 
        mux_b_sel    <= instruction(6 downto 4); 
        add_sub_sel  <= '0';
        jump_flag    <= '0';
        jump_addr    <= instruction(2 downto 0); -- Extract ddd bits[cite: 1]

        case opcode is
            --------------------------------------------------
            -- MOVI R, d (Format: 10 RRR 000 dddd)[cite: 1]
            --------------------------------------------------
            when "10" =>
                reg_write_en <= '1';
                load_sel     <= '1'; -- Direct immediate value d to register[cite: 1]

            --------------------------------------------------
            -- ADD Ra, Rb (Format: 00 RaRaRa RbRbRb 0000)[cite: 1]
            --------------------------------------------------
            when "00" =>
                reg_write_en <= '1';
                load_sel     <= '0'; -- Select 4-bit Add/Sub Unit output[cite: 1]
                add_sub_sel  <= '0'; -- Set ALU to Addition[cite: 1]

            --------------------------------------------------
            -- NEG R (Format: 01 RRR 000 0000)[cite: 1]
            --------------------------------------------------
            when "01" =>
                reg_write_en <= '1';
                load_sel     <= '0';
                add_sub_sel  <= '1';     -- Set ALU to Subtraction[cite: 1]
                mux_a_sel    <= "000";   -- Hardwire input A to R0 (which is 0)[cite: 1]
                mux_b_sel    <= instruction(9 downto 7); -- Input B is register R[cite: 1]

            --------------------------------------------------
            -- JZR R, d (Format: 11 RRR 000 0ddd)[cite: 1]
            --------------------------------------------------
            when "11" =>
                reg_write_en <= '0'; -- Ensure no register is written
                mux_a_sel    <= instruction(9 downto 7); -- Route register R to check bus[cite: 1]
                jump_addr    <= instruction(2 downto 0); -- Address d[cite: 1]
                
                -- If R == 0, jump flag triggers PC <- d[cite: 1]
                if reg_check_val = "0000" then
                    jump_flag <= '1'; 
                else
                    jump_flag <= '0'; -- Else PC <- PC + 1[cite: 1]
                end if;

            when others =>
                null;
        end case;
    end process;

end Behavioral;