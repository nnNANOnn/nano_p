# Testing Guide — Nanoprocessor

> Methods for verifying every component and the whole nanoprocessor.
> Covers VHDL testbenches, simulation procedure, expected waveforms,
> and on-board hardware verification.

The verification strategy is layered:

1. **Unit testbenches** for each component, run individually in
   behavioural simulation.
2. **Integration testbench** for the full top-level, also in simulation.
3. **Hardware test** on the Basys 3, using the LEDs and 7-seg display
   as the visible end-to-end check.

Each layer catches different bugs. Run them in this order — bugs
surface earliest at the smallest level.

---

## Table of Contents

1. [Testing philosophy](#1-testing-philosophy)
2. [How to run a simulation in Vivado](#2-how-to-run-a-simulation-in-vivado)
3. [Half Adder (HA)](#3-half-adder-ha)
4. [Full Adder (FA)](#4-full-adder-fa)
5. [4-bit RCA (RCA_4)](#5-4-bit-rca-rca_4)
6. [3-bit RCA (RCA_3 / Adder_3bits)](#6-3-bit-rca-rca_3--adder_3bits)
7. [4-bit Add/Sub Unit (ALU)](#7-4-bit-addsub-unit-alu)
8. [D Flip-Flop](#8-d-flip-flop)
9. [Generic Register (Reg)](#9-generic-register-reg)
10. [Decoders (2-to-4, 3-to-8)](#10-decoders-2-to-4-3-to-8)
11. [Multiplexers (8-to-1, MUX_8_4, Mux_2_3, Mux_2_4)](#11-multiplexers-8-to-1-mux_8_4-mux_2_3-mux_2_4)
12. [Register Bank](#12-register-bank)
13. [Program Counter and PC_Inc](#13-program-counter-and-pc_inc)
14. [Program ROM](#14-program-rom)
15. [Instruction Decoder](#15-instruction-decoder)
16. [Clock Divider](#16-clock-divider)
17. [7-Segment Driver](#17-7-segment-driver)
18. [Top-level Nanoprocessor](#18-top-level-nanoprocessor)
19. [Hardware verification on the Basys 3](#19-hardware-verification-on-the-basys-3)
20. [Test summary checklist](#20-test-summary-checklist)

---

## 1. Testing philosophy

Three rules:

* **Test inputs come from the team members' index numbers** (lab
  Step 2). Pick the last 4 bits of each member's index as the test
  vector for adders/muxes/registers. This is the convention the lab
  asks for and gives the demo discussion something concrete to point
  at.
* **Self-checking testbenches beat eyeballed waveforms.** The provided
  `instruction_decoder_tb.vhd` is a self-checking testbench using
  `assert ... severity error`. Aim to write your own component
  testbenches in the same style.
* **One thing at a time.** A big simulation that fails tells you
  *something* broke, not *what*. Always test the smallest reasonable
  block first, then bring up the next layer once it's solid.

---

## 2. How to run a simulation in Vivado

For any simulation testbench:

1. Open the project (per `vivado_setup.md`).
2. In the *Sources* pane, switch to **Simulation Sources**.
3. Right-click the testbench → **Set as Top**.
4. *Flow Navigator* → **Run Simulation → Run Behavioral Simulation**.
5. The simulation pops the *waveform window*. Toggle the run time at
   the top toolbar and click **Run**.
6. Drag signals from the *Objects* pane into the wave window. Right-
   click → **Radix → Unsigned Decimal** for cleaner display of
   numeric values.
7. Read the *Tcl Console* at the bottom for any `assert` failures.
   No red lines = passed.

To re-run after editing a file: click the **Restart** button (small
arrow with a vertical bar), then **Run** again.

---

## 3. Half Adder (HA)

**What to verify:**
* `S = A XOR B` for all 4 input combinations
* `C = A AND B` for all 4 input combinations

**Sample testbench** (save as `sim/tb_HA.vhd`):

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_HA is
end tb_HA;

architecture Behavioral of tb_HA is
    signal A, B, S, C : STD_LOGIC := '0';
begin
    UUT : entity work.HA port map (A => A, B => B, S => S, C => C);

    stim : process
    begin
        for i in 0 to 3 loop
            (A, B) <= std_logic_vector(to_unsigned(i, 2));
            wait for 10 ns;
            assert S = (A xor B) report "HA sum wrong" severity error;
            assert C = (A and B) report "HA carry wrong" severity error;
        end loop;
        report "HA test complete" severity note;
        wait;
    end process;
end Behavioral;
```

**Expected waveform:**

| A | B | S | C |
|---|---|---|---|
| 0 | 0 | 0 | 0 |
| 0 | 1 | 1 | 0 |
| 1 | 0 | 1 | 0 |
| 1 | 1 | 0 | 1 |

---

## 4. Full Adder (FA)

**What to verify:** all 8 combinations of (A, B, C_in) produce
correct (S, C_out).

**Test approach:** loop over `i = 0..7`, decode `i` into (A, B, C_in),
check `S = (A XOR B XOR C_in)` and `C_out = (A·B + (A XOR B)·C_in)`.

**Expected truth table:**

| A | B | C_in | S | C_out |
|---|---|---|---|---|
| 0 | 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 1 | 0 |
| 0 | 1 | 0 | 1 | 0 |
| 0 | 1 | 1 | 0 | 1 |
| 1 | 0 | 0 | 1 | 0 |
| 1 | 0 | 1 | 0 | 1 |
| 1 | 1 | 0 | 0 | 1 |
| 1 | 1 | 1 | 1 | 1 |

---

## 5. 4-bit RCA (RCA_4)

**What to verify:**
* `S = A + B + C_in` for representative cases including: `A = B = 0`,
  `A = "1111", B = "0001"` (overflow), `A = "0111", B = "0001"`
  (signed overflow).
* `C_out` = carry out of bit 3.
* `C_in_last` = carry into bit 3 (used by ALU's overflow detector).

**Sample test cases** (use team-member indices for non-trivial vectors):

| A | B | C_in | Expected S | Expected C_out | Expected C_in_last |
|---|---|---|---|---|---|
| 0000 | 0000 | 0 | 0000 | 0 | 0 |
| 0011 | 0101 | 0 | 1000 | 0 | 1 |
| 1111 | 0001 | 0 | 0000 | 1 | 1 |
| 0111 | 0001 | 0 | 1000 | 0 | 1 |
| 1010 | 0110 | 0 | 0000 | 1 | 1 |

The fourth row is the canonical *signed-overflow* case: `7 + 1 = 8`,
which wraps to `-8` in 2's complement; the C_in/C_out mismatch flags it.

---

## 6. 3-bit RCA (RCA_3 / Adder_3bits)

**Use case in the design:** PC incrementer (`PC_Inc` hardwires
`B = "001"`, `C_in = '0'`).

**What to verify:**
* `A_out = A_in + 1` for `A_in = 0..7`.
* For `A_in = "111"`, `A_out = "000"` (wrap around — `C_out` is
  intentionally open).

| A_in | A_out (expected) |
|---|---|
| 000 | 001 |
| 001 | 010 |
| 010 | 011 |
| 011 | 100 |
| 100 | 101 |
| 101 | 110 |
| 110 | 111 |
| 111 | 000 (wraps) |

Drive the testbench with a process that ramps `A_in` through 0..7 in
10 ns steps and observe `A_out`.

---

## 7. 4-bit Add/Sub Unit (ALU)

The most important arithmetic component. Test all four combinations
of CTRL × overflow.

**Required cases:**

| CTRL | A_AS | B_AS | Expected S_AS | Expected Zero | Expected OverFlow |
|---|---|---|---|---|---|
| 0 (add) | 0011 | 0101 | 1000 | 0 | 0 |
| 0 (add) | 0111 | 0001 | 1000 | 0 | **1** (signed overflow: 7+1) |
| 0 (add) | 1111 | 0001 | 0000 | **1** | 0 |
| 1 (sub) | 0101 | 0011 | 0010 | 0 | 0 |
| 1 (sub) | 0011 | 0011 | 0000 | **1** | 0 |
| 1 (sub) | 1000 | 0001 | 0111 | 0 | **1** (signed overflow: -8 - 1) |

The third row covers `Zero` after an addition.
The fifth row covers `Zero` after a subtraction (the JZR check path).
The second and sixth rows cover the OverFlow flag in both directions.

**Test for NEG (the lab's NEG instruction):**

| CTRL | A_AS | B_AS | Notes | Expected S_AS |
|---|---|---|---|---|
| 1 | 0000 | 0001 | NEG R when R = 1 | 1111 (= -1) |
| 1 | 0000 | 1010 | NEG R when R = -6 | 0110 (= 6) |
| 1 | 0000 | 0000 | NEG R when R = 0 | 0000 (= 0) |

These are the operand polarities the decoder produces for `NEG R`.

---

## 8. D Flip-Flop

**What to verify:**
* On rising clock with `En = '1'` and `Res = '0'`, `Q` follows `D` and
  `Qbar = NOT D`.
* On rising clock with `Res = '1'`, `Q` clears regardless of `D`.
* On rising clock with `En = '0'`, `Q` does **not** change (holds).
* Between rising clock edges, `Q` is stable (no glitches on `D`
  propagate to `Q`).

**Procedure:** drive a 50 MHz simulation clock, toggle `D`, `En`,
and `Res` between edges, observe `Q`.

**Expected behaviour:**

| Cycle | D | En | Res | Q after edge | Why |
|---|---|---|---|---|---|
| 1 | 1 | 1 | 0 | 1 | Normal load |
| 2 | 0 | 0 | 0 | 1 | Hold (En low) |
| 3 | 0 | 1 | 0 | 0 | Normal load |
| 4 | 1 | 1 | 1 | 0 | Reset wins |
| 5 | 1 | 1 | 0 | 1 | Reset released |

---

## 9. Generic Register (Reg)

**What to verify:**
* For `N = 4` (the bank's setting), the register holds 4 bits in
  parallel.
* All 4 bits update simultaneously on the rising edge when `En = '1'`.
* Reset zeroes all 4 bits.

**Procedure:** Same as the D_FF tests but with a 4-bit `D`. Run for at
least 5 clock cycles with three different `D` values and a reset
mid-stream. Reuse `tb_Register_Bank.vhd`'s clock-generator process.

---

## 10. Decoders (2-to-4, 3-to-8)

**What to verify (`Decoder_2_to_4`):**
* For each of `I = 00, 01, 10, 11` and `EN = '1'`, exactly one bit of
  `Y` is high — namely `Y(to_integer(unsigned(I)))`.
* For `EN = '0'`, `Y = 0000` regardless of `I`.

**What to verify (`Decoder_3_to_8`):**
* Same one-hot property for all 8 input addresses.
* `EN = '0'` clamps the entire output to zero — this is the property
  the register bank's master `Write_En` relies on, so make sure it's
  rock solid.

**Sample tabular check for `Decoder_3_to_8` with EN = '1':**

| I (3-bit) | Y (8-bit, MSB-first) |
|---|---|
| 000 | 00000001 |
| 001 | 00000010 |
| 010 | 00000100 |
| ... | ... |
| 111 | 10000000 |

---

## 11. Multiplexers (8-to-1, MUX_8_4, Mux_2_3, Mux_2_4)

### 11.1 `Mux_8_to_1`

**What to verify:** for each `S = 0..7` with `EN = '1'`, `Y = D(S)`.
With `EN = '0'`, `Y = '0'` regardless.

**Procedure:** drive a fixed `D = "10101010"` and ramp `S` through
all 8 values in 10 ns steps. Watch `Y` toggle between `1` and `0`
following the bit pattern.

### 11.2 `MUX_8_4`

**What to verify:** for each `S = 0..7`, `Y = D(S)` where `D` is a
`data_buses` (8 × 4 bits).

**Procedure:** initialise `D` with eight unique 4-bit values
(`D(0)="0000", D(1)="0001", ..., D(7)="0111"` is convenient), then
ramp `S` and observe `Y` step through `0000, 0001, …, 0111`.

### 11.3 `Mux_2_3`

**What to verify:** `S = '0' ⇒ Y = D0`, `S = '1' ⇒ Y = D1`.

| S | D0 | D1 | Expected Y |
|---|---|---|---|
| 0 | 010 | 101 | 010 |
| 1 | 010 | 101 | 101 |

### 11.4 `Mux_2_4`

Same as `Mux_2_3` but with 4-bit lanes.

| S | D0 | D1 | Expected Y |
|---|---|---|---|
| 0 | 1010 | 0101 | 1010 |
| 1 | 1010 | 0101 | 0101 |

---

## 12. Register Bank

**Provided testbench:** `sim/tb_Register_Bank.vhd`.

**What to verify:**
* Reset clears R1..R7 to `0000`.
* R0 stays `0000` always — even when `Reg_En = "000"` and the
  testbench drives a non-zero `Data`.
* Writes propagate only when `Write_En = '1'`. Setting `Write_En = '0'`
  freezes the bank.
* Each register can be written independently.

**Expected waveform (after stimulus in the provided testbench):**

| Time (relative) | Action | R0 | R1 | R2 | R3 | R7 |
|---|---|---|---|---|---|---|
| t = 0 | Reset | 0 | 0 | 0 | 0 | 0 |
| t = 25 ns | Try write to R0 | 0 (unchanged) | 0 | 0 | 0 | 0 |
| t = 45 ns | Write 0011 to R1 | 0 | 0011 | 0 | 0 | 0 |
| t = 65 ns | Write 0101 to R2 | 0 | 0011 | 0101 | 0 | 0 |
| t = 85 ns | Write 1010 to R3 | 0 | 0011 | 0101 | 1010 | 0 |
| t = 105 ns | Write 1111 to R7 | 0 | 0011 | 0101 | 1010 | 1111 |
| t = 125 ns | Write_En = 0 | 0 | 0011 | 0101 | 1010 | 1111 (no change) |

In the wave window, group the 8 outputs as
`Data_Buses[0..7]` with **Radix → Hexadecimal** for compact display.

---

## 13. Program Counter and `PC_Inc`

**What to verify (combined):**
* From reset, PC = "000".
* On each clock with `A` driven by `PC_Inc(M)`, PC increments by 1
  every cycle.
* PC wraps from 7 to 0 (sanity check; never used by the lab program
  but should still work).
* Reset can interrupt mid-stream.

**Sample testbench skeleton:**

```vhdl
-- Wire PC's A input directly to PC_Inc's output, so the PC
-- naturally increments every cycle.
inc : entity work.PC_Inc port map (A_in => M_curr, A_out => A_next);
pc  : entity work.PC     port map (A => A_next, Res => Res, Clk => Clk, M => M_curr);

stim : process
begin
    Res <= '1';  wait for 25 ns;
    Res <= '0';
    -- Run for 10 cycles and watch M_curr step through 0..7..0..1.
    wait for 200 ns;
    -- Force a mid-stream reset
    Res <= '1';  wait for 20 ns;
    Res <= '0';
    wait;
end process;
```

**Expected:** `M_curr` waveform = 0,1,2,3,4,5,6,7,0,1, then back to 0
on the second reset.

---

## 14. Program ROM

**What to verify:** the 8 hard-coded machine words appear correctly
on `I` for `ROM_address = 0..7`.

**Procedure:** drive `ROM_address` from 0 to 7 in unit-time steps and
read `I`. Compare against the table in `docs/program_rom.md`:

| Addr | I (binary) |
|---|---|
| 000 | 101110000000 |
| 001 | 100010000011 |
| 010 | 100100000001 |
| 011 | 010100000000 |
| 100 | 001110010000 |
| 101 | 000010100000 |
| 110 | 110010000110 |
| 111 | 110000000100 |

---

## 15. Instruction Decoder

**Provided testbench:** `sim/instruction_decoder_tb.vhd`.

**What it covers:** all 4 opcodes, corner registers (R0 and R7),
corner immediates (0 and 15), the JZR-not-taken case, the JZR-taken
case, an unconditional jump (`JZR R0`), and per-bit zero-detector
verification.

The testbench is **self-checking** — every case ends with
`assert ... severity error`. After running:

1. Open the *Tcl Console* at the bottom of Vivado.
2. Look for any line starting with `Failure` or `Error`. None means
   you passed.
3. The final `==== Instruction Decoder testbench finished ====`
   message confirms the run completed.

**Manual sanity sweep** — for each of these inputs, confirm the
output table from `docs/instruction_decoder.md`:

| Instruction | reg_en_sel | reg_write_en | load_sel | mux_a_sel | mux_b_sel | add_sub_sel | jump_flag |
|---|---|---|---|---|---|---|---|
| `MOVI R3, 9`  | 011 | 1 | 1 | 011 | 000 | 0 | 0 |
| `ADD R4, R5`  | 100 | 1 | 0 | 100 | 101 | 0 | 0 |
| `NEG R6`      | 110 | 1 | 0 | 000 | 110 | 1 | 0 |
| `JZR R7, 5`, R7=0 | 111 | 0 | 0 | 111 | 000 | 0 | 1 |
| `JZR R7, 5`, R7=4 | 111 | 0 | 0 | 111 | 000 | 0 | 0 |

---

## 16. Clock Divider

**What to verify:** with `DIV_LIMIT = N`, `Slow_Clk` toggles every
`N` rising edges of `Clk_in`.

**Recommendation:** override the generic to a small value for
simulation:

```vhdl
clk_div : entity work.Clock_Divider
    generic map ( DIV_LIMIT => 5 )      -- toggle every 5 cycles
    port map (
        Clk_in => Clk, Res => Res, Slow_Clk => Slow_Clk
    );
```

**Expected:** `Slow_Clk` rises after 5 input cycles, falls after the
next 5, etc. With a 100 MHz simulated input, that's 50 ns high, 50 ns
low — easy to see in the waveform.

For real hardware (`DIV_LIMIT = 100_000_000`), the slow clock period
is 2 seconds. Verify on the board with a stopwatch by counting LD0
toggles.

---

## 17. 7-Segment Driver

**What to verify:** for `Value = 0..15`, `Cathodes` matches the
7-segment encoding from `docs/clock_and_io.md`. `Anodes = 1110`
always (only AN0 lit).

**Procedure:** ramp `Value` through 0..15 in 10 ns steps. Watch
`Cathodes` change. The visual interpretation:

| `Value` | digit shown | `Cathodes` (active low: 0 = lit) |
|---|---|---|
| 0000 | 0 | 0000001 |
| 0001 | 1 | 1001111 |
| 0010 | 2 | 0010010 |
| ... | ... | ... |
| 1111 | F | 0111000 |

In hardware, the right-most digit of the 4-digit display lights up
when programmed.

---

## 18. Top-level Nanoprocessor

**Provided testbench:** `sim/Nanoprocessor_tb.vhd`.

**What it covers:** end-to-end execution of the Step-4 program with
the slow clock running. Watches `Result_LED` (= R7), `Zero_LED`,
`Carry_LED`.

### 18.1 Pre-simulation step

The testbench overrides the DUT's `DIV_LIMIT` generic to `5`, so one
slow-clock period is 100 ns and the program completes in ~1.6 µs.
No source edits required — just open `Nanoprocessor_tb` and run.

If you need to change the simulation speed, edit the
`generic map ( DIV_LIMIT => 5 )` line inside `Nanoprocessor_tb.vhd`.
The DUT itself defaults to `DIV_LIMIT = 100_000_000` for hardware,
which is what synthesis uses.

### 18.2 Signals to add to the wave window

Drag these from the *Objects* pane:

| Group | Signals |
|---|---|
| **Clock + reset** | `Clk_100MHz`, `Reset_Btn`, `UUT/Slow_Clk` |
| **PC + ROM** | `UUT/PC_curr`, `UUT/I_bus` |
| **Decoder outputs** | `UUT/reg_en_sel`, `UUT/reg_write_en`, `UUT/load_sel`, `UUT/imm_val`, `UUT/mux_a_sel`, `UUT/mux_b_sel`, `UUT/add_sub_sel`, `UUT/jump_flag`, `UUT/jump_addr` |
| **ALU + datapath** | `UUT/Mux_A_out`, `UUT/Mux_B_out`, `UUT/ALU_result`, `UUT/Data_Bus` |
| **Register bank** | `UUT/Reg_Outputs[0]` … `UUT/Reg_Outputs[7]` (radix: hex) |
| **Outputs** | `Result_LED`, `Zero_LED`, `Carry_LED` |

### 18.3 Expected trace

After reset, with the slow clock ticking every 100 ns, you should
observe (slow-clock cycle by cycle):

| Slow cycle | PC_curr | I_bus | Decoded action | R7 |
|---|---|---|---|---|
| 0 | 000 | 101110000000 | MOVI R7, 0 | 0 |
| 1 | 001 | 100010000011 | MOVI R1, 3 | 0 |
| 2 | 010 | 100100000001 | MOVI R2, 1 | 0 |
| 3 | 011 | 010100000000 | NEG  R2     | 0 |
| 4 | 100 | 001110010000 | ADD  R7, R1 | 3 |
| 5 | 101 | 000010100000 | ADD  R1, R2 | 3 |
| 6 | 110 | 110010000110 | JZR  R1, 6  → not taken | 3 |
| 7 | 111 | 110000000100 | JZR  R0, 4  → taken | 3 |
| 8 | 100 | (loop back)  | ADD  R7, R1 | 5 |
| 9 | 101 | …             | ADD  R1, R2 | 5 |
| 10 | 110 | …            | JZR  R1, 6  → not taken | 5 |
| 11 | 111 | …            | JZR  R0, 4  → taken | 5 |
| 12 | 100 | …            | ADD  R7, R1 | **6** |
| 13 | 101 | …            | ADD  R1, R2 | 6 |
| 14 | 110 | …            | JZR  R1, 6  → **taken** (R1=0) | 6 |
| 15 | 110 | …            | self-loop, parked | 6 |

After cycle 15, the PC stays at `110` and R7 stays at `0110` for the
rest of the simulation. `Zero_LED` lights briefly during cycles 13
and 14 (when ALU produces 0 from `R1 + R2`).

### 18.4 Self-check assertion

The testbench already ends with a self-check:

```vhdl
assert Result_LED = "0110"
    report "FAIL: R7 expected 0110 (=6), got something else."
    severity failure;

report "PASS: nanoprocessor computed sum 1+2+3 = 6 correctly."
    severity note;
```

The run is silent on success and very loud on failure — exactly the
property a CI pipeline needs.

---

## 19. Hardware verification on the Basys 3

After `vivado_setup.md` §10 has programmed the board:

### 19.1 Visual checklist

1. The board's **DONE** LED is steady on (FPGA programmed).
2. Press and release **BTNC**. Within ~1 second, **LD0** should light
   up.
3. Watch the LEDs. Every 1 second, the displayed value of R7 changes:
   ```
   0000 → 0011 → 0011 → 0011 → 0011 → 0101 → 0101 → 0101 → 0101 → 0110
   ```
   The slow tick-rate is what makes each step visible. (The *exact*
   pattern depends on which slow-clock edge triggered at startup; if
   you press BTNC again you see a fresh run.)
4. After ~14 seconds the LEDs lock to **`0110`** (= 6) and stay there.
5. The right-most 7-segment digit shows **`6`**.
6. **LD14** flashes briefly on the cycle that produces zero
   (`R1 += R2 = 0`).

### 19.2 What to do if it doesn't work

| Symptom | Diagnosis | Fix |
|---|---|---|
| LEDs never light up | Clock divider not running | Check `DIV_LIMIT = 100_000_000` in source; rebuild |
| LEDs all on, never change | Reset stuck high | Verify BTNC pin (U18); if a different button works, fix XDC |
| LEDs change too fast (every ~1 ms) | DIV_LIMIT generic was overridden in synthesis | The hardware top uses the default 100_000_000; no override should be set in implementation runs |
| LEDs end up at `0011` (= 3) | Program halted at the wrong place | Compare your ROM contents with `docs/program_rom.md` exactly |
| LEDs end up at `0101` (= 5) | NEG R2 not working | Verify ALU operand polarity (A=0, B=R) and CTRL=1 |
| 7-seg blank | Anodes wrong polarity or wrong digit | Confirm `Anodes = "1110"` and the right-most digit is AN0 (pin U2) |
| 7-seg shows wrong digit but LEDs are correct | `Cathodes` lookup wrong | Cross-check `Seven_Seg_Driver.vhd` against `docs/clock_and_io.md` |
| Random/changing display every reset | Race condition on PC at startup | Hold BTNC for at least one slow-clock period before releasing |

### 19.3 Demo script (for the lab evaluation)

A clean demo runs in three minutes:

1. Show the board, identify BTNC, LD0..LD3, LD14, LD15, the 7-segment.
2. Press BTNC. As the LEDs step, narrate what each cycle does:
   "MOVI R7, 0 — R7 is 0. Now R1 = 3. Now R2 = 1. Now R2 is negated.
   Now R7 is added with R1 — see, R7 is 3. Now R1 -= 1, R1 is 2.
   And so on."
3. After R7 reaches 6, press BTNC and let it run again to show
   determinism.
4. Open `instruction_decoder_tb` in Vivado and run it; show the
   self-check passes.
5. Walk through `Nanoprocessor.vhd` to show how the structural
   components plug together, referencing Fig. 1 of the lab.
6. (Optional, for extra-credit "least-gates": quote the gate count
   from `docs/instruction_decoder.md` and explain the wire-only
   optimisations.)

---

## 20. Test summary checklist

Before declaring the project done, verify every box:

- [ ] All component testbenches compile without errors.
- [ ] `tb_HA`, `tb_FA`, `tb_RCA_4`, `tb_RCA_3` all show correct sums
      and carries.
- [ ] `tb_AddSub` covers add, subtract, zero, and overflow.
- [ ] `tb_D_FF`, `tb_Reg` show clean load/hold/reset behaviour.
- [ ] `tb_Decoder_2_to_4` and `tb_Decoder_3_to_8` produce correct
      one-hot outputs and respect EN.
- [ ] `tb_Mux_8_to_1`, `tb_MUX_8_4`, `tb_Mux_2_3`, `tb_Mux_2_4` route
      the right input to the right output.
- [ ] `tb_Register_Bank` (provided) shows R0 stays zero, R1..R7 latch
      with `Write_En`, and the bank freezes when `Write_En = '0'`.
- [ ] `tb_PC` shows the PC ramping 0..7 and back to 0.
- [ ] `tb_Program_ROM` returns the right 12-bit word for every
      address.
- [ ] `instruction_decoder_tb` (provided) reports no `Failure` /
      `Error`.
- [ ] `tb_Clock_Divider` toggles `Slow_Clk` after `DIV_LIMIT` cycles.
- [ ] `tb_Seven_Seg_Driver` produces the correct cathode pattern for
      every hex value.
- [ ] `Nanoprocessor_tb` (with `DIV_LIMIT = 5`) ends with R7 = `0110`
      and the PC parked at 6.
- [ ] On hardware: pressing BTNC produces the expected LED + 7-seg
      sequence and stops on `6`.
- [ ] Lab report (Step 7) is written, including the assembly program,
      machine code, all VHDL, all timing diagrams, and a per-team-
      member contribution log.

When every box is ticked, the nanoprocessor is verifiably correct end
to end. Time to celebrate — and to think about the extra-credit
extensions in `docs/program_rom.md` §5.
