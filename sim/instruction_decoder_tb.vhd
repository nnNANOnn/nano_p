----------------------------------------------------------------------------------
-- Testbench: instruction_decoder_tb
-- Verifies every control output of instruction_decoder for all 4 instructions
-- (MOVI, ADD, NEG, JZR), including corner cases:
--   * R0 and R7 (lowest & highest register addresses)
--   * Immediate = 0 and 15 (full 4-bit range)
--   * JZR with R==0 (jump taken) and R/=0 (jump not taken)
--   * The exact instruction sequence from the lab description (page 3)
--
-- Each block is a self-checking assertion: if any expected output is wrong,
-- the simulator prints a clear FAILURE message and continues.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity instruction_decoder_tb is
end instruction_decoder_tb;

architecture Behavioral of instruction_decoder_tb is

    component instruction_decoder
        Port (
            instruction   : in  STD_LOGIC_VECTOR (11 downto 0);
            reg_check_val : in  STD_LOGIC_VECTOR (3 downto 0);
            reg_en_sel    : out STD_LOGIC_VECTOR (2 downto 0);
            reg_write_en  : out STD_LOGIC;
            load_sel      : out STD_LOGIC;
            imm_val       : out STD_LOGIC_VECTOR (3 downto 0);
            mux_a_sel     : out STD_LOGIC_VECTOR (2 downto 0);
            mux_b_sel     : out STD_LOGIC_VECTOR (2 downto 0);
            add_sub_sel   : out STD_LOGIC;
            jump_flag     : out STD_LOGIC;
            jump_addr     : out STD_LOGIC_VECTOR (2 downto 0)
        );
    end component;

    -- Stimulus
    signal instruction   : STD_LOGIC_VECTOR (11 downto 0) := (others => '0');
    signal reg_check_val : STD_LOGIC_VECTOR (3 downto 0)  := (others => '0');

    -- Observed outputs
    signal reg_en_sel    : STD_LOGIC_VECTOR (2 downto 0);
    signal reg_write_en  : STD_LOGIC;
    signal load_sel      : STD_LOGIC;
    signal imm_val       : STD_LOGIC_VECTOR (3 downto 0);
    signal mux_a_sel     : STD_LOGIC_VECTOR (2 downto 0);
    signal mux_b_sel     : STD_LOGIC_VECTOR (2 downto 0);
    signal add_sub_sel   : STD_LOGIC;
    signal jump_flag     : STD_LOGIC;
    signal jump_addr     : STD_LOGIC_VECTOR (2 downto 0);

begin

    uut: instruction_decoder
        port map (
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

    stim_proc: process
    begin
        wait for 100 ns;

        ----------------------------------------------------------------
        -- TEST 1 : MOVI R1, 10  (lab example, line 0)
        --   binary  = 10 001 000 1010
        ----------------------------------------------------------------
        instruction   <= "100010001010";
        reg_check_val <= "0000";
        wait for 50 ns;
        assert reg_write_en = '1'   report "T1 MOVI: reg_write_en should be 1" severity error;
        assert load_sel     = '1'   report "T1 MOVI: load_sel should be 1 (immediate)" severity error;
        assert reg_en_sel   = "001" report "T1 MOVI: reg_en_sel should be 001 (R1)" severity error;
        assert imm_val      = "1010" report "T1 MOVI: imm_val should be 1010 (=10)" severity error;
        assert jump_flag    = '0'   report "T1 MOVI: jump_flag should be 0" severity error;

        ----------------------------------------------------------------
        -- TEST 2 : MOVI R7, 15  (corner: highest reg, max immediate)
        --   binary  = 10 111 000 1111
        ----------------------------------------------------------------
        instruction <= "101110001111";
        wait for 50 ns;
        assert reg_en_sel = "111" report "T2 MOVI: reg_en_sel should be 111 (R7)" severity error;
        assert imm_val    = "1111" report "T2 MOVI: imm_val should be 1111 (=15)" severity error;
        assert load_sel   = '1'   report "T2 MOVI: load_sel should be 1" severity error;

        ----------------------------------------------------------------
        -- TEST 3 : MOVI R0, 0  (corner: write to read-only R0, imm=0)
        --   binary  = 10 000 000 0000
        ----------------------------------------------------------------
        instruction <= "100000000000";
        wait for 50 ns;
        assert reg_en_sel = "000" report "T3 MOVI: reg_en_sel should be 000 (R0)" severity error;
        assert imm_val    = "0000" report "T3 MOVI: imm_val should be 0000" severity error;
        -- R0 is hardwired to 0 in the register bank, so this write is silently ignored

        ----------------------------------------------------------------
        -- TEST 4 : ADD R1, R2  (lab example, line 3)
        --   binary  = 00 001 010 0000
        ----------------------------------------------------------------
        instruction <= "000010100000";
        wait for 50 ns;
        assert reg_write_en = '1'   report "T4 ADD: reg_write_en should be 1" severity error;
        assert load_sel     = '0'   report "T4 ADD: load_sel should be 0 (ALU)" severity error;
        assert add_sub_sel  = '0'   report "T4 ADD: add_sub_sel should be 0 (add)" severity error;
        assert reg_en_sel   = "001" report "T4 ADD: dest should be R1" severity error;
        assert mux_a_sel    = "001" report "T4 ADD: mux_a should select R1" severity error;
        assert mux_b_sel    = "010" report "T4 ADD: mux_b should select R2" severity error;

        ----------------------------------------------------------------
        -- TEST 5 : ADD R7, R6  (corner: top two registers)
        --   binary  = 00 111 110 0000
        ----------------------------------------------------------------
        instruction <= "001111100000";
        wait for 50 ns;
        assert reg_en_sel = "111" report "T5 ADD: dest should be R7" severity error;
        assert mux_a_sel  = "111" report "T5 ADD: mux_a should select R7" severity error;
        assert mux_b_sel  = "110" report "T5 ADD: mux_b should select R6" severity error;

        ----------------------------------------------------------------
        -- TEST 6 : NEG R2  (lab example, line 2)
        --   binary  = 01 010 000 0000
        --   ALU does 0 - R2, so mux_a=R0, mux_b=R2, add_sub=1
        ----------------------------------------------------------------
        instruction <= "010100000000";
        wait for 50 ns;
        assert reg_write_en = '1'   report "T6 NEG: reg_write_en should be 1" severity error;
        assert load_sel     = '0'   report "T6 NEG: load_sel should be 0 (ALU)" severity error;
        assert add_sub_sel  = '1'   report "T6 NEG: add_sub_sel should be 1 (subtract)" severity error;
        assert reg_en_sel   = "010" report "T6 NEG: dest should be R2" severity error;
        assert mux_a_sel    = "000" report "T6 NEG: mux_a must be R0 (zero)" severity error;
        assert mux_b_sel    = "010" report "T6 NEG: mux_b must be R2" severity error;

        ----------------------------------------------------------------
        -- TEST 7 : JZR R1, 7  (lab example, line 4 -- jump NOT taken)
        --   binary  = 11 001 000 0111
        --   reg_check_val = 1010  (i.e. R1 = 10, non-zero)
        ----------------------------------------------------------------
        instruction   <= "110010000111";
        reg_check_val <= "1010";
        wait for 50 ns;
        assert reg_write_en = '0'   report "T7 JZR: reg_write_en must be 0" severity error;
        assert mux_a_sel    = "001" report "T7 JZR: mux_a must route R1 to check" severity error;
        assert jump_addr    = "111" report "T7 JZR: jump_addr should be 111 (=7)" severity error;
        assert jump_flag    = '0'   report "T7 JZR: jump_flag must be 0 when R/=0" severity error;

        ----------------------------------------------------------------
        -- TEST 8 : JZR R1, 7  (same instruction -- jump TAKEN)
        --   reg_check_val = 0000  (i.e. R1 = 0, jump should fire)
        ----------------------------------------------------------------
        reg_check_val <= "0000";
        wait for 50 ns;
        assert jump_flag = '1' report "T8 JZR: jump_flag must be 1 when R=0" severity error;
        assert jump_addr = "111" report "T8 JZR: jump_addr should be 111" severity error;

        ----------------------------------------------------------------
        -- TEST 9 : JZR R0, 3  (lab example, line 5 -- unconditional jump)
        --   binary  = 11 000 000 0011
        --   R0 is hardwired to 0, so jump always fires.
        ----------------------------------------------------------------
        instruction   <= "110000000011";
        reg_check_val <= "0000";
        wait for 50 ns;
        assert jump_flag = '1'   report "T9 JZR R0: jump_flag must be 1 (R0 always 0)" severity error;
        assert jump_addr = "011" report "T9 JZR R0: jump_addr should be 011 (=3)" severity error;

        ----------------------------------------------------------------
        -- TEST 10 : JZR with single-bit set (sanity for zero detector)
        ----------------------------------------------------------------
        instruction   <= "110010000111";
        reg_check_val <= "1000";   wait for 20 ns;
        assert jump_flag = '0' report "T10a JZR: 1000 is not zero" severity error;
        reg_check_val <= "0100";   wait for 20 ns;
        assert jump_flag = '0' report "T10b JZR: 0100 is not zero" severity error;
        reg_check_val <= "0010";   wait for 20 ns;
        assert jump_flag = '0' report "T10c JZR: 0010 is not zero" severity error;
        reg_check_val <= "0001";   wait for 20 ns;
        assert jump_flag = '0' report "T10d JZR: 0001 is not zero" severity error;
        reg_check_val <= "0000";   wait for 20 ns;
        assert jump_flag = '1' report "T10e JZR: 0000 IS zero, must jump" severity error;

        report "==== InstructionDecoder testbench finished. Check above for any FAILURE/ERROR. ====" severity note;
        wait;
    end process;

end Behavioral;