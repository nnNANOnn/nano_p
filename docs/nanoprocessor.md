# Nanoprocessor — Top-Level Integration

> The 4-bit, 4-instruction nanoprocessor of CS1050 Lab 9-10, fully assembled.
> This is the "big picture" document: it explains how every component
> introduced in the other markdown files comes together to fetch, decode,
> and execute one instruction per slow-clock cycle.

---

## Table of Contents

1. [Module overview](#1-module-overview)
2. [Block diagram and signal map](#2-block-diagram-and-signal-map)
3. [Top-level ports (every pin)](#3-top-level-ports-every-pin)
4. [Cycle-by-cycle datapath](#4-cycle-by-cycle-datapath)
5. [Step-4 program trace (sum 1..3 → R7)](#5-step-4-program-trace-sum-13--r7)
6. [Why this design is efficient](#6-why-this-design-is-efficient)
7. [Compilation order for Vivado](#7-compilation-order-for-vivado)
8. [Simulation tips](#8-simulation-tips)
9. [Running on the Basys 3 board](#9-running-on-the-basys-3-board)
10. [Files in this project](#10-files-in-this-project)

---

## 1. Module overview

`Nanoprocessor.vhd` is the top-level structural entity. It owns no logic
of its own; it only instantiates and wires together the building blocks.
This separation — combinational logic in the small components, structural
plumbing at the top — is what keeps the design auditable and synthesizable.

The processor obeys a four-instruction ISA defined in Table 1 of the lab
handout:

| `I[11:10]` | Mnemonic | Effect |
|---|---|---|
| `00` | `ADD Ra, Rb` | `Ra ← Ra + Rb` |
| `01` | `NEG R`      | `R  ← −R` (2's complement) |
| `10` | `MOVI R, d`  | `R  ← d` (4-bit immediate) |
| `11` | `JZR R, d`   | if `R == 0` then `PC ← d` else `PC ← PC + 1` |

Every instruction completes in **one slow-clock cycle**: fetch + decode +
execute + write-back happen as combinational propagation between two
rising edges of the slow clock.

---

## 2. Block diagram and signal map

```
              Clk_100MHz                  Reset_Btn
                  │                            │
                  ▼                            ▼
         ┌─────────────────┐                   │
         │ Clock_Divider   │                   │  (async reset to PC and bank)
         │   (1 sec/2 sec) │                   │
         └────────┬────────┘                   │
                  │ Slow_Clk                   │
                  │                            │
                  ▼                            ▼
   ┌─────────────────────────────────────────────────────┐
   │                                                     │
   │  ┌────┐   M(2:0)  ┌──────────────┐   I(11:0)        │
   │  │ PC │──────────▶│ Program ROM  │────────┬────────▶│   to Decoder
   │  └────┘           └──────────────┘        │         │
   │     ▲                                     │         │
   │     │ PC_next                             │         │
   │     │                                     ▼         │
   │  ┌──────────────┐    ┌────────────────────────────┐ │
   │  │ Mux_2_3      │◀───│ Instruction Decoder        │ │
   │  │ (PC source)  │    │  (combinational)           │ │
   │  └────┬─────────┘    └─────┬──────┬──────┬────────┘ │
   │       │                    │      │      │          │
   │       │ jump_addr  reg_en  │ mux  │ ALU  │ load     │
   │       │   ▲         sel    │ A/B  │ ctrl │ sel      │
   │       │   │         wr_en  │ sel  │      │          │
   │       │ ┌─┴───────────┐    │      │      │          │
   │       │ │ Mux_2_3     │    │      │      │          │
   │       │ │ jumps in    │    │      │      │          │
   │       │ └─┬───────────┘    │      │      │          │
   │       │   │ PC+1 from RCA_3│      │      │          │
   │       │ ┌─┴───────────┐    │      │      │          │
   │       │ │ PC_Inc      │    │      │      │          │
   │       │ └─────────────┘    │      │      │          │
   │       │                    ▼      ▼      │          │
   │       │  ┌───────────┐ ┌───────┐ ┌───┐   │          │
   │       │  │ MUX_8_4 A │ │ALU 4b │ │8x4│   │          │
   │       │  │           │ │       │ │mux│   │          │
   │       │  └─────┬─────┘ └───┬───┘ └─┬─┘   │          │
   │       │        │           │       │     │          │
   │       │        └────┬──────┘       │     │          │
   │       │             ▼              │     │          │
   │       │      reg_check_val         │     │          │
   │       │      (back to decoder)     │     │          │
   │       │                            │     │          │
   │       │                  ┌─────────▼─┐   │          │
   │       │                  │ Mux_2_4   │◀──┘          │
   │       │                  │ (data bus)│              │
   │       │                  └─────┬─────┘              │
   │       │                        │ Data_Bus (4 bits)  │
   │       │                        ▼                    │
   │       │                ┌────────────────┐           │
   │       │                │ Register Bank  │           │
   │       │                │ R0=0, R1..R7   │           │
   │       │                └──┬─────────────┘           │
   │       │                   │ 8 x Data_Bus            │
   │       │                   │                         │
   │       │     ┌─────────────┘                         │
   │       │     ▼                                       │
   │       │  to MUX_8_4 A and B                         │
   │       └────────────────────────────────────▶ jump   │
   │                                                     │
   └─────────────────────────────────────────────────────┘
        │                              │
        ▼                              ▼
   Result_LED, Zero_LED, Carry_LED   Cathodes/Anodes (7-seg)
```

Bus naming follows the lab handout:

| Symbol | Width | Meaning |
|---|---|---|
| `D` | 4 | data bus (value being written into the register bank) |
| `I` | 12 | instruction bus (Program ROM output) |
| `M` | 3 | memory address (PC value sent to ROM) |
| `R` | 3 | register-bank address (`reg_en_sel`) |

---

## 3. Top-level ports (every pin)

```vhdl
entity Nanoprocessor is
    Port (
        Clk_100MHz : in  STD_LOGIC;
        Reset_Btn  : in  STD_LOGIC;
        Result_LED : out STD_LOGIC_VECTOR(3 downto 0);
        Zero_LED   : out STD_LOGIC;
        Carry_LED  : out STD_LOGIC;
        Cathodes   : out STD_LOGIC_VECTOR(6 downto 0);
        Anodes     : out STD_LOGIC_VECTOR(3 downto 0)
    );
end Nanoprocessor;
```

| Port | Width | Direction | Board pin (Basys 3) | Notes |
|---|---|---|---|---|
| `Clk_100MHz` | 1 | in | W5 | 100 MHz oscillator |
| `Reset_Btn`  | 1 | in | U18 (BTNC) | active high, async resets PC and bank |
| `Result_LED` | 4 | out | U16, E19, U19, V19 | R7 displayed on LD0..LD3 |
| `Zero_LED`   | 1 | out | P1 (LD14) | ALU's Zero flag |
| `Carry_LED`  | 1 | out | L1 (LD15) | ALU's signed-overflow flag (carry-style indicator) |
| `Cathodes`   | 7 | out | W7,W6,U8,V8,U5,V5,U7 | 7-segment {a,b,c,d,e,f,g}, active low |
| `Anodes`     | 4 | out | U2,U4,V4,W4 | digit selects, active low |

Pin assignments live in `constraints/Basys3.xdc`.

---

## 4. Cycle-by-cycle datapath

A single execution cycle has **four stages**, all happening between two
rising edges of `Slow_Clk`:

### 4.1 Fetch
The current PC value `M` indexes Program ROM, which combinationally
emits the 12-bit instruction word `I` onto the Instruction Bus.

### 4.2 Decode
The Instruction Decoder consumes `I` and produces every control wire
the rest of the datapath needs: `reg_en_sel`, `reg_write_en`,
`load_sel`, `imm_val`, `mux_a_sel`, `mux_b_sel`, `add_sub_sel`,
`jump_flag`, and `jump_addr`. This is purely combinational — no clock,
no state.

### 4.3 Execute
Two 8-way 4-bit muxes pick the two ALU operands from the eight register
outputs. The 4-bit Add/Sub unit computes either `A + B` or `A − B`,
producing the result, the `Zero` flag, and the signed-overflow flag.

For `JZR`, Mux A's output also loops back into the decoder as
`reg_check_val`. The decoder NORs all four bits to detect zero and
gates that with `is_JZR` to produce `jump_flag`.

### 4.4 Write-back
The 2-way 4-bit data-bus mux picks between the ALU result (for
`ADD`/`NEG`) and the immediate field (for `MOVI`). The selected value
sits on the Data Bus, which feeds every register in the bank. The
3-to-8 decoder inside the register bank (gated by `reg_write_en`)
asserts exactly one register's `En` line, and at the next rising
clock edge that register latches the Data Bus.

In parallel, the PC computes its next value: the 3-bit adder produces
`PC + 1`, and the 2-way 3-bit mux picks between that and `jump_addr`
based on `jump_flag`. The chosen value is loaded into the PC register
on the same clock edge.

So one instruction = one slow clock = one PC step + one register write.

---

## 5. Step-4 program trace (sum 1..3 → R7)

Program (held in Program ROM, addresses 0..7):

```
addr  asm              binary                 comment
 0    MOVI R7, 0       10 111 000 0000        sum := 0
 1    MOVI R1, 3       10 001 000 0011        ctr := 3
 2    MOVI R2, 1       10 010 000 0001        tmp := 1
 3    NEG  R2          01 010 000 0000        tmp := -1
 4    ADD  R7, R1      00 111 001 0000        sum += ctr
 5    ADD  R1, R2      00 001 010 0000        ctr -= 1
 6    JZR  R1, 6       11 001 000 0110        halt: jump to self if ctr=0
 7    JZR  R0, 4       11 000 000 0100        unconditional jump back to 4
```

Execution trace:

```
PC=0   R7 ← 0
PC=1   R1 ← 3
PC=2   R2 ← 1
PC=3   R2 ← -1     (1111 in 2's complement)
PC=4   R7 ← 0 + 3 = 3
PC=5   R1 ← 3 + (-1) = 2
PC=6   R1 = 2 ≠ 0 → no jump → PC=7
PC=7   R0 = 0 → unconditional jump → PC=4
PC=4   R7 ← 3 + 2 = 5
PC=5   R1 ← 2 + (-1) = 1
PC=6   R1 = 1 ≠ 0 → no jump → PC=7
PC=7   jump → PC=4
PC=4   R7 ← 5 + 1 = 6     ← FINAL CORRECT SUM
PC=5   R1 ← 1 + (-1) = 0
PC=6   R1 = 0 → jump to 6 → PC=6  (self-loop, halt)
PC=6   stays parked here forever
```

After 16 slow-clock cycles, R7 = 6, displayed as `0110` on LD0..LD3
and as the digit `6` on the 7-segment display.

---

## 6. Why this design is efficient

Three deliberate choices keep the gate count low and the cycle count short:

### 6.1 Wire-only decoder fields
`reg_en_sel = I(9..7)`, `imm_val = I(3..0)`, and `jump_addr = I(2..0)`
are *just slices* of the instruction. We do not gate them with the opcode;
downstream logic (the 3-to-8 decoder's enable, the data-bus mux, the
PC-source mux) is the one that decides whether to use them. That saves
three multiplexers worth of gates.

### 6.2 Instruction-format coincidences
For `MOVI` (opcode `10`) and `JZR` (opcode `11`), bits `I[6:4]` are
*always* `000`. So `mux_b_sel = I(6..4)` naturally selects R0 (the
read-only zero register) for those opcodes — no extra mux is needed.
This makes `JZR` ALU = R + 0 = R, which is exactly what we want for
the zero check.

### 6.3 Shared not-gates and one-pass control
`mux_a_sel` and `mux_b_sel` both need `NOT is_NEG`. The synthesiser
shares that inverter, so the entire decoder fits in roughly **21 basic
2-input gates plus one NOR4** (see `instruction_decoder.md`).

### 6.4 One-cycle execution
Because the decoder is combinational and the ALU is a simple ripple
adder, one instruction completes per slow clock. There is no fetch
register, no pipeline, no microcode. The slow clock is set to ~2 sec
per tick only so a human can watch the LEDs change — the actual
critical path is ~ten gate delays (<100 ns on the Basys 3 fabric).

---

## 7. Compilation order for Vivado

Add the files to your Vivado project in this order to make Vivado happy
(packages first, then their consumers):

```
packages/buses.vhd
packages/adders.vhd

src/arithmetic_unit/HA.vhd
src/arithmetic_unit/FA.vhd
src/arithmetic_unit/RCA_4.vhd
src/arithmetic_unit/Adder_3bits.vhd
src/arithmetic_unit/AddSub_4.vhd
src/arithmetic_unit/D_FF.vhd

src/register_bank/Reg.vhd
src/register_bank/Decoder_2_to_4.vhd
src/register_bank/Decoder_3_8.vhd
src/register_bank/Register_Bank.vhd

src/arithmetic_unit/PC.vhd
src/arithmetic_unit/PC_Inc.vhd

src/mux/Mux_8_to_1.vhd
src/mux/MUX_8_4.vhd
src/mux/Mux_2_3.vhd
src/mux/Mux_2_4.vhd

src/program_rom/Program_Rom.vhd
src/instruction_decoder/instruction_decoder.vhd

src/io/Clock_Divider.vhd
src/io/Seven_Seg_Driver.vhd

src/Nanoprocessor.vhd                       <-- top-level

constraints/Basys3.xdc
sim/instruction_decoder_tb.vhd              (sim only)
sim/tb_Register_Bank.vhd                    (sim only)
sim/Nanoprocessor_tb.vhd                    (sim only)
```

---

## 8. Simulation tips

1. Open `sim/Nanoprocessor_tb.vhd` and set it as the simulation top.
2. The testbench overrides the DUT's `DIV_LIMIT` generic to `5`, so
   the slow clock cycles every ~100 ns of simulation time and the
   program finishes in ~1.6 µs.  No source-level edits are needed.
3. Add the following waveforms:
   - `UUT/Slow_Clk`, `UUT/PC_curr`, `UUT/I_bus`
   - `UUT/reg_en_sel`, `UUT/reg_write_en`, `UUT/load_sel`, `UUT/imm_val`
   - `UUT/mux_a_sel`, `UUT/mux_b_sel`, `UUT/add_sub_sel`
   - `UUT/Mux_A_out`, `UUT/Mux_B_out`, `UUT/ALU_result`, `UUT/Data_Bus`
   - `UUT/Reg_Outputs(7)`  ← this is R7, the answer
4. Run for 5 µs.  You should see R7 step through 0 → 3 → 5 → 6 and
   stay parked at `0110`.  The testbench's self-check `assert` confirms
   `Result_LED = "0110"` at the end.
5. Hardware synthesis uses the default `DIV_LIMIT = 100_000_000` (no
   action needed).

For unit tests, use `sim/instruction_decoder_tb.vhd` and
`sim/tb_Register_Bank.vhd`.

---

## 9. Running on the Basys 3 board

1. Confirm `DIV_LIMIT` is back to `100_000_000`.
2. In Vivado, set `Nanoprocessor` as the top entity.
3. Run synthesis → implementation → generate bitstream.
4. Program the Basys 3 over USB.
5. Press **BTNC** once to reset. The slow clock starts; LEDs change
   every 1 second.
6. Watch LD0..LD3 step from `0000` (R7 = 0) up through the partial
   sums to **`0110`** (R7 = 6). The 7-segment display shows the same
   value as a hex digit.
7. After a few cycles, LD14 (`Zero_LED`) lights briefly when ALU
   computes a zero result (e.g. when ctr reaches 0).

Pressing BTNC at any time restarts the program from address 0.

---

## 10. Files in this project

```
nano_p/
├── packages/
│   ├── buses.vhd
│   └── adders.vhd
├── src/
│   ├── Nanoprocessor.vhd                  ← TOP LEVEL
│   ├── arithmetic_unit/
│   │   ├── HA.vhd, FA.vhd
│   │   ├── RCA_4.vhd, Adder_3bits.vhd
│   │   ├── AddSub_4.vhd
│   │   ├── D_FF.vhd
│   │   ├── PC.vhd, PC_Inc.vhd
│   ├── register_bank/
│   │   ├── Reg.vhd
│   │   ├── Decoder_2_to_4.vhd, Decoder_3_8.vhd
│   │   └── Register_Bank.vhd
│   ├── mux/
│   │   ├── Mux_8_to_1.vhd
│   │   ├── MUX_8_4.vhd
│   │   ├── Mux_2_3.vhd                    ← NEW
│   │   └── Mux_2_4.vhd                    ← NEW
│   ├── program_rom/
│   │   └── Program_Rom.vhd
│   ├── instruction_decoder/
│   │   └── instruction_decoder.vhd
│   └── io/
│       ├── Clock_Divider.vhd              ← NEW
│       └── Seven_Seg_Driver.vhd           ← NEW
├── constraints/
│   └── Basys3.xdc                         ← NEW
├── sim/
│   ├── instruction_decoder_tb.vhd
│   ├── tb_Register_Bank.vhd
│   └── Nanoprocessor_tb.vhd               ← NEW (top-level)
└── docs/
    ├── nanoprocessor.md                   ← this file
    ├── instruction_decoder.md
    ├── arithmetic_unit.md
    ├── program_counter.md
    ├── register_bank.md
    ├── multiplexers.md
    ├── program_rom.md
    └── clock_and_io.md
```
