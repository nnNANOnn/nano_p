# Instruction Decoder — Nanoprocessor Lab 9–10

> Module 4 of the Nanoprocessor team project: **"The Brain Surgeon"**.
> The Instruction Decoder is the control unit of the 4-bit nanoprocessor. It
> takes the 12-bit instruction word coming out of Program ROM and produces
> every control signal the rest of the datapath needs in one combinational
> sweep — no clock, no state, no latches.

This README is exhaustive *on purpose*. Use the Table of Contents to skip to
what you need.

---

## Table of Contents

1. [What this module is and is not](#1-what-this-module-is-and-is-not)
2. [Where it sits in the nanoprocessor](#2-where-it-sits-in-the-nanoprocessor)
3. [The instruction set in full detail](#3-the-instruction-set-in-full-detail)
4. [Port description (every pin, every bit)](#4-port-description-every-pin-every-bit)
5. [The decoded truth table](#5-the-decoded-truth-table)
6. [Boolean equations and gate count](#6-boolean-equations-and-gate-count)
7. [Why each clever bit is clever (optimisations)](#7-why-each-clever-bit-is-clever-optimisations)
8. [Walk-through of every instruction](#8-walk-through-of-every-instruction)
9. [The two testbenches](#9-the-two-testbenches)
10. [The Step-4 assembly program (sum 1..3 → R7)](#10-the-step-4-assembly-program-sum-13--r7)
11. [How to run the simulations in Vivado](#11-how-to-run-the-simulations-in-vivado)
12. [Integration notes for the rest of the team](#12-integration-notes-for-the-rest-of-the-team)
13. [Common pitfalls and FAQ](#13-common-pitfalls-and-faq)
14. [Files in this project](#14-files-in-this-project)

---

## 1. What this module *is* and *is not*

The Instruction Decoder is a **purely combinational** block. It contains:

- No clock input
- No register, no flip-flop, no latch
- No internal state of any kind

Every output is a fresh function of the current instruction (and, for `JZR`,
of the current value of the register being checked). The only place state
lives in the nanoprocessor is in the Program Counter (PC) and in the
Register Bank — both built by other team members.

What the decoder **does** do:

- Decode the 2-bit opcode (`I[11:10]`) into one of 4 instructions.
- Tell the Register Bank which register (if any) to write this cycle.
- Tell the data-bus mux whether the value being written should come from
  the ALU or from the immediate field.
- Tell the two 8-way 4-bit muxes which registers to feed into the ALU.
- Tell the ALU whether to add or subtract.
- Tell the PC whether to take the jump address from the instruction or just
  go to PC+1.

---

## 2. Where it sits in the nanoprocessor

```
            ┌──────────────────────┐
   12-bit   │                      │  3   reg_en_sel  ────► 3-to-8 dec ► register bank write enables
 instruction│                      │  1   reg_write_en ───► enable of that 3-to-8 dec
   ────────►│                      │  1   load_sel    ────► 2-way 4-bit data-bus mux select
            │  Instruction Decoder │  4   imm_val     ────► immediate input of that data-bus mux
            │   (this module)      │  3   mux_a_sel   ────► left  8-way 4-bit mux (ALU input A)
            │                      │  3   mux_b_sel   ────► right 8-way 4-bit mux (ALU input B)
            │                      │  1   add_sub_sel ────► ALU's add/subtract select
   4-bit    │                      │  1   jump_flag   ────► 2-way 3-bit PC-source mux select
 reg_check_val─►                   │  3   jump_addr   ────► data input of that PC mux
            └──────────────────────┘
```

`reg_check_val` is the 4-bit output of the **left 8-way 4-bit mux** (mux A)
fed back as an input to the decoder. The decoder uses this only when
executing `JZR`, to detect whether the selected register is zero.

This feedback is shown in Fig. 1 of the lab document as the wire labelled
"Register check for jump".

---

## 3. The instruction set in full detail

The processor understands exactly 4 instructions, all 12 bits wide. The
opcode is the top two bits: `I[11:10]`.

### 3.1 Opcode map

| `I[11:10]` | Mnemonic | Effect |
| --- | --- | --- |
| `00` | `ADD Ra, Rb` | `Ra ← Ra + Rb` |
| `01` | `NEG R`      | `R  ← −R` (2's complement negation) |
| `10` | `MOVI R, d`  | `R  ← d` (load 4-bit immediate) |
| `11` | `JZR R, d`   | if `R == 0` then `PC ← d` else `PC ← PC + 1` |

### 3.2 Bit-by-bit instruction layout

```
bit:        11 10  9  8  7  6  5  4  3  2  1  0
            ┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
MOVI R, d : │ 1│ 0│ R│ R│ R│ 0│ 0│ 0│ d│ d│ d│ d│   d ∈ [0,15]
            ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
ADD Ra,Rb : │ 0│ 0│Ra│Ra│Ra│Rb│Rb│Rb│ 0│ 0│ 0│ 0│
            ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
NEG  R    : │ 0│ 1│ R│ R│ R│ 0│ 0│ 0│ 0│ 0│ 0│ 0│
            ├──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┼──┤
JZR  R, d : │ 1│ 1│ R│ R│ R│ 0│ 0│ 0│ 0│ d│ d│ d│   d ∈ [0,7]
            └──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
```

### 3.3 Two beautiful coincidences in this layout

The lab designer chose this layout cleverly. Two facts let us **delete
hardware** from the decoder:

1. **Bits `I[6:4]` are `000` for every instruction except `ADD`.** That
   means we can leave `mux_b_sel` connected straight to bits `I[6:4]` for
   `MOVI` and `JZR`, and it will naturally select R0 — *no* mux needed for
   those cases.
2. **The destination register address is always bits `I[9:7]` for the
   three writing instructions** (`MOVI` / `ADD` / `NEG`). For `JZR` we set
   `reg_write_en = 0` so the value of `reg_en_sel` does not matter; we
   leave `reg_en_sel` connected straight to `I[9:7]` (a piece of wire), and
   the gate of `reg_write_en` blocks any spurious writes.

Both of these turn into "0 gates" in the synthesised decoder.

---

## 4. Port description (every pin, every bit)

Defined in
[InstructionDecoder.srcs/sources_1/new/instruction_decoder.vhd](InstructionDecoder.srcs/sources_1/new/instruction_decoder.vhd).

### 4.1 Inputs

| Name | Width | Source | Description |
| --- | --- | --- | --- |
| `instruction` | 12 | Program ROM | The current 12-bit instruction word. `instruction(11:10)` is the opcode. |
| `reg_check_val` | 4 | Output of mux A (left 8-way 4-bit mux) | The 4-bit value of the register currently selected on `mux_a_sel`. The decoder NORs all four bits to detect zero, which is needed for `JZR`. |

### 4.2 Outputs

| Name | Width | Goes to | Description |
| --- | --- | --- | --- |
| `reg_en_sel` | 3 | The 3-bit address input of the register-bank's 3-to-8 decoder | Which register to write to this cycle. Equal to `I[9:7]` for every instruction. |
| `reg_write_en` | 1 | The **enable** input of that 3-to-8 decoder | `'1'` for `MOVI`, `ADD`, `NEG`. `'0'` for `JZR`. When low, the 3-to-8 decoder must drive all 8 of its outputs to 0 so no register's flip-flops latch. |
| `load_sel` | 1 | Select line of the 2-way 4-bit data-bus mux | `'1'` ⇒ put the immediate field on the data bus (used by `MOVI`); `'0'` ⇒ put the ALU output on the data bus (used by `ADD`, `NEG`). |
| `imm_val` | 4 | The "immediate" data input of that data-bus mux | Equal to `I[3:0]`. Only used when `load_sel='1'` (i.e. on `MOVI`). |
| `mux_a_sel` | 3 | Select of the left 8-way 4-bit mux (ALU input A) | Which register feeds the ALU's A input. See truth table below. |
| `mux_b_sel` | 3 | Select of the right 8-way 4-bit mux (ALU input B) | Which register feeds the ALU's B input. |
| `add_sub_sel` | 1 | The ALU's add/subtract select | `'0'` ⇒ add, `'1'` ⇒ subtract. Only `NEG` raises this; everything else uses add. |
| `jump_flag` | 1 | Select of the 2-way 3-bit PC-source mux | `'1'` ⇒ load PC with `jump_addr`, `'0'` ⇒ load PC with PC+1. Only `JZR` (with `R == 0`) raises this. |
| `jump_addr` | 3 | The "jump-address" data input of that PC mux | Equal to `I[2:0]` (the low 3 bits of the d field). |

### 4.3 Why `reg_write_en` AND the 3-to-8 decoder both exist

Some students wonder why we need both `reg_en_sel` *and* `reg_write_en`.
Couldn't we just have the 3-to-8 decoder always be active, and use
`reg_en_sel` to point at R0 when we don't want to write?

We could — except that R0 is hardwired to constant `0000`, and the 3-to-8
decoder would still try to clock R0's "register" (which doesn't actually
have flip-flops). That would work, but it's *bad style*: it conflates "I
don't want to write" with "I want to write to the read-only register".

The cleaner approach (which we use) is to give the 3-to-8 decoder an
**enable** input. When `reg_write_en = '0'`, the decoder forces all 8 of
its outputs to 0, and no register's clock-enable line is asserted. This is
unambiguous and keeps the two semantics separate.

---

## 5. The decoded truth table

This is the paper diagram the lab tells you to draw in **Step 1**, in full.
`X` means don't-care (the value of that signal is irrelevant for that
instruction; we pick whatever is cheapest to generate).

| `op` | `is_ADD` | `is_NEG` | `is_MOVI` | `is_JZR` | `reg_write_en` | `load_sel` | `add_sub_sel` | `mux_a_sel` | `mux_b_sel` | `jump_flag` |
|---|---|---|---|---|---|---|---|---|---|---|
| `00` (ADD)  | 1 | 0 | 0 | 0 | **1** | 0 | 0 | I(9:7) (Ra) | I(6:4) (Rb) | 0 |
| `01` (NEG)  | 0 | 1 | 0 | 0 | **1** | 0 | **1** | **`000`** (R0) | I(9:7) (R) | 0 |
| `10` (MOVI) | 0 | 0 | 1 | 0 | **1** | **1** | X | X | X | 0 |
| `11` (JZR)  | 0 | 0 | 0 | 1 | **0** | X | X | I(9:7) (R) | I(6:4)=`000` (R0) | `R==0` |

Two non-obvious entries deserve a sentence each:

- **NEG: A = 0, B = R, subtract.** The ALU computes `A − B = 0 − R = −R`.
  The naive reading "put R on A and zero on B with subtract" gives
  `R − 0 = R`, which is wrong. So R must go on the **B** input.
- **JZR: A = R, B = 0, add.** The ALU computes `R + 0 = R`. We never
  *write* that result back (because `reg_write_en = 0`), but we route mux
  A's output back into the decoder as `reg_check_val` and detect zero
  there. Putting R on A (not B) lets us reuse the same mux-A wire for both
  operand selection and zero detection — a single wire, two purposes.

---

## 6. Boolean equations and gate count

These map 1:1 to the lines of
[instruction_decoder.vhd](InstructionDecoder.srcs/sources_1/new/instruction_decoder.vhd).

```
op1 = I(11),  op0 = I(10)

is_ADD  = ¬op1 · ¬op0
is_NEG  = ¬op1 ·  op0
is_MOVI =  op1 · ¬op0
is_JZR  =  op1 ·  op0          -- 4 AND2 + 2 NOT (NOTs shared) = ~6 gates

reg_en_sel    = I(9..7)        -- WIRE, 0 gates
imm_val       = I(3..0)        -- WIRE, 0 gates
jump_addr     = I(2..0)        -- WIRE, 0 gates

reg_write_en  = ¬is_JZR        -- 1 NOT (or merge with is_JZR's NAND)
load_sel      = is_MOVI        -- already computed, 0 extra gates
add_sub_sel   = is_NEG         -- already computed, 0 extra gates

mux_a_sel(i)  = I(i+7) · ¬is_NEG          for i in {0,1,2}     -- 3 AND2 + 1 shared NOT
mux_b_sel(i)  = (I(i+7) · is_NEG)
              + (I(i+4) · ¬is_NEG)        for i in {0,1,2}     -- 6 AND2 + 3 OR2

r_is_zero     = ¬(rcv(3)+rcv(2)+rcv(1)+rcv(0))                  -- 1 NOR4
jump_flag     = is_JZR · r_is_zero                              -- 1 AND2
```

**Total gate budget (rough count, 2-input gates unless noted):**

| Stage | Gates |
| --- | --- |
| Opcode one-hot decode | ~6 |
| `reg_write_en`, `load_sel`, `add_sub_sel` | 1 (only the NOT) |
| `mux_a_sel` (3 bits) | 4 (3 AND2 + 1 shared NOT) |
| `mux_b_sel` (3 bits) | 9 (6 AND2 + 3 OR2) |
| Zero detector | 1 NOR4 |
| `jump_flag` | 1 AND2 |
| **Total** | **~21 basic gates + 1 NOR4** |

That number is what to quote during the demo for the
"least-gates" extra-credit category in Step 5 of the lab.

---

## 7. Why each clever bit is clever (optimisations)

Three concrete tricks pay back in gate count and clarity:

### 7.1 Wire-only outputs

`reg_en_sel`, `imm_val`, and `jump_addr` are *just slices of the
instruction*. We do not gate them with the opcode — instead we let
downstream logic (the 3-to-8 decoder's enable, the data-bus mux, the
PC-source mux) decide whether to use them. This saves three multiplexers'
worth of gates.

### 7.2 Sharing `is_NEG`'s NOT

`mux_a_sel` needs `¬is_NEG`. So does `mux_b_sel`. Vivado will share that
inverter across all 6 affected bits, leaving us with **one** NOT instead
of six.

### 7.3 Letting MOVI / JZR's "000" bits do the work for free

For `MOVI` (opcode `10`) and `JZR` (opcode `11`), bits `I[6:4]` of the
instruction are *always* `000` per the instruction format. So
`mux_b_sel = I(6..4)` for those opcodes naturally selects R0 — we did not
have to add a third mux input or a special case for them.

`MOVI`'s `mux_b_sel` is don't-care anyway (the ALU output gets discarded
by `load_sel = '1'`), but the same wire feeds it for free. `JZR` actively
needs R0 here so it gets `R + 0 = R` from the ALU, which makes the
decoder's zero check trivially correct. Two birds, one wire.

---

## 8. Walk-through of every instruction

### 8.1 `MOVI R, d`

Cycle effect: write the 4-bit immediate `d` into register `R`.

| Signal | Value | Why |
|---|---|---|
| `is_MOVI` | 1 | `op = 10` |
| `reg_en_sel` | I(9:7) = R | Destination register |
| `reg_write_en` | 1 | We are writing |
| `load_sel` | 1 | Pick the immediate side of the data-bus mux |
| `imm_val` | I(3:0) = d | The literal we want |
| `mux_a_sel` | I(9:7) (don't-care) | ALU output is unused this cycle |
| `mux_b_sel` | I(6:4)=`000` (don't-care) | Same |
| `add_sub_sel` | 0 (don't-care) | Same |
| `jump_flag` | 0 | Not a jump |
| `jump_addr` | I(2:0) (don't-care) | PC-mux ignores it |

Datapath flow: `imm_val` → data-bus mux (`load_sel=1` selects it) → data
bus → register `R` (which is enabled by the 3-to-8 decoder because
`reg_write_en=1` and `reg_en_sel=R`) → on the next clock edge, `R ← d`.

### 8.2 `ADD Ra, Rb`

Cycle effect: `Ra ← Ra + Rb`.

| Signal | Value | Why |
|---|---|---|
| `is_ADD` | 1 | `op = 00` |
| `reg_en_sel` | I(9:7) = Ra | Destination is Ra |
| `reg_write_en` | 1 | We are writing |
| `load_sel` | 0 | Pick the ALU side of the data-bus mux |
| `mux_a_sel` | I(9:7) = Ra | ALU's A input is Ra |
| `mux_b_sel` | I(6:4) = Rb | ALU's B input is Rb |
| `add_sub_sel` | 0 | Add |
| `jump_flag` | 0 | Not a jump |

Datapath flow: mux A outputs Ra, mux B outputs Rb → ALU computes Ra+Rb →
data-bus mux selects ALU side → data bus = Ra+Rb → register Ra gets
enabled and latches the sum on next clock edge.

### 8.3 `NEG R`

Cycle effect: `R ← −R` (2's complement negation).

| Signal | Value | Why |
|---|---|---|
| `is_NEG` | 1 | `op = 01` |
| `reg_en_sel` | I(9:7) = R | Destination is R |
| `reg_write_en` | 1 | We are writing |
| `load_sel` | 0 | ALU side |
| `mux_a_sel` | `000` (R0) | A = 0 |
| `mux_b_sel` | I(9:7) = R | B = R |
| `add_sub_sel` | 1 | Subtract |
| `jump_flag` | 0 | Not a jump |

Datapath flow: mux A outputs R0 = 0, mux B outputs R → ALU computes
A − B = 0 − R = −R → data-bus mux selects ALU side → R gets overwritten
with −R.

> **Why A=0 and B=R, not the other way around?**
> The ALU computes `A − B`. We want `−R = 0 − R`, so the minuend (A) must
> be 0 and the subtrahend (B) must be R. If we did A=R, B=0, we would
> compute `R − 0 = R`, which is the *identity*, not negation.

### 8.4 `JZR R, d`

Cycle effect: if `R == 0`, jump to address `d`; otherwise PC ← PC+1.

| Signal | Value | Why |
|---|---|---|
| `is_JZR` | 1 | `op = 11` |
| `reg_en_sel` | I(9:7) = R (don't-care) | Blocked by `reg_write_en=0` |
| `reg_write_en` | **0** | We do **not** write |
| `load_sel` | 1 (don't-care) | No write happens |
| `mux_a_sel` | I(9:7) = R | Route R to mux A so it appears on `reg_check_val` |
| `mux_b_sel` | I(6:4) = `000` (R0) | Routed for free by the instruction format |
| `add_sub_sel` | 0 (don't-care) | ALU output is unused |
| `jump_flag` | `R == 0` | Drives the PC-source mux |
| `jump_addr` | I(2:0) = d | The jump target |

Datapath flow: mux A outputs R → travels back into decoder as
`reg_check_val` → 4-input NOR detects R==0 → ANDed with `is_JZR` →
`jump_flag`. If `jump_flag=1`, the PC-source mux selects `jump_addr` and
the PC loads `d` on the next clock edge. Otherwise, the PC-source mux
selects PC+1 from the 3-bit adder.

---

## 9. The testbench

Lives in
[InstructionDecoder.srcs/sim_1/new/instruction_decoder_tb.vhd](InstructionDecoder.srcs/sim_1/new/instruction_decoder_tb.vhd).

A self-checking test with 10 cases that cover:

| # | Case | What it proves |
|---|---|---|
| 1 | `MOVI R1, 10` (lab example) | Basic MOVI works |
| 2 | `MOVI R7, 15` | Highest register, max immediate |
| 3 | `MOVI R0, 0` | Lowest register, min immediate (write to R0 is OK; register bank ignores it) |
| 4 | `ADD R1, R2` (lab example) | Basic ADD works |
| 5 | `ADD R7, R6` | Top two registers |
| 6 | `NEG R2` (lab example) | mux A = R0, mux B = R, sub asserted |
| 7 | `JZR R1, 7` with R1 ≠ 0 | Jump NOT taken |
| 8 | `JZR R1, 7` with R1 = 0 | Jump TAKEN |
| 9 | `JZR R0, 3` | R0 always 0 ⇒ jump always taken |
| 10 | Each individual bit of `reg_check_val` | Zero detector is a *real* 4-input NOR (not "is bit 0 zero?") |

Every case ends with `assert ... severity error` lines that print a clear
failure message into the Vivado Tcl console if anything is wrong. If
nothing fails, you get the success banner at the end.

---

## 10. The Step-4 assembly program (sum 1..3 → R7)

Required by Step 4 of the lab. The Program-ROM teammate hard-codes these
8 machine words into the ROM, in this exact order.

```
addr  asm              machine code (binary)   hex     comment
 0    MOVI R7, 0       10 111 000 0000         0xB80   sum := 0
 1    MOVI R1, 3       10 001 000 0011         0x883   ctr := 3
 2    MOVI R2, 1       10 010 000 0001         0x901   tmp := 1
 3    NEG  R2          01 010 000 0000         0x500   tmp := -1
 4    ADD  R7, R1      00 111 001 0000         0x390   sum += ctr
 5    ADD  R1, R2      00 001 010 0000         0x0A0   ctr -= 1
 6    JZR  R1, 6       11 001 000 0110         0xC86   if ctr=0, halt (self-loop)
 7    JZR  R0, 4       11 000 000 0100         0xC04   else jump back to addr 4
```

### 10.1 Step-by-step trace

```
PC=0  R7=0
PC=1  R1=3
PC=2  R2=1
PC=3  R2=-1                      (R2 = 1111 in 2's complement)
PC=4  R7 = 0 + 3 = 3
PC=5  R1 = 3 + (-1) = 2
PC=6  R1=2 ≠ 0, no jump          PC ← 7
PC=7  R0=0, jump taken           PC ← 4
PC=4  R7 = 3 + 2 = 5
PC=5  R1 = 2 - 1 = 1
PC=6  R1=1 ≠ 0, no jump          PC ← 7
PC=7  R0=0, jump taken           PC ← 4
PC=4  R7 = 5 + 1 = 6             ✓ correct sum
PC=5  R1 = 1 - 1 = 0
PC=6  R1=0, jump TAKEN to 6      PC ← 6 (self-loop, halt)
PC=6  R1 still 0, jump again     PC ← 6 ...   forever
```

R7 stays at 6 forever after the loop terminates. On the Basys 3, this is
displayed as `0110` on LD0..LD3 and as `6` on the 7-segment display.

### 10.2 Why the program is exactly 8 instructions

The PC is 3 bits wide (Fig. 1 of the lab), so Program ROM has only 8
slots (addresses 0..7). Our program uses every one of them. There's no
slack to add extra instructions, so each one has to earn its keep.

### 10.3 The "halt" trick

The instruction set has no `HALT`. The standard trick is to use a `JZR`
that jumps to its own address: once we land there, R1 stays 0 (nothing is
modifying it), so the JZR keeps firing and parking the PC at the same
address. The result register is preserved.

### 10.4 The unconditional back-edge trick

Address 7 is `JZR R0, 4`. R0 is the read-only zero register, so this `JZR`
*always* fires — we have effectively turned `JZR` into an unconditional
jump. This is the same trick MIPS uses with `BEQ $zero, $zero, label`.

---

## 11. How to run the simulations in Vivado

1. Open `InstructionDecoder.xpr` in Vivado 2025.1 (or compatible).
2. In the **Sources** pane, switch to the **Simulation Sources** tab.
3. Right-click the testbench you want to run:
   - For pass/fail unit testing: `instruction_decoder_tb`
   - For waveform tracing of the real program: `decoder_tb`
4. Choose **Set as Top**.
5. Click **Run Simulation → Run Behavioral Simulation**.
6. After the simulation runs:
   - For `instruction_decoder_tb`, read the **Tcl console** at the bottom.
     If you see no `Failure`/`Error` lines and the final `==== ...
     finished ====` note, all tests passed.
   - For `decoder_tb`, look at the **waveform viewer**. Expand
     `instruction`, `reg_check_val`, and the outputs to read off the
     control signals at every cycle.

### 11.1 Useful waveform groupings

For the system trace, the most useful groups are:

- `instruction`, `reg_check_val` (inputs)
- `reg_en_sel`, `reg_write_en`, `load_sel`, `imm_val` (write-side)
- `mux_a_sel`, `mux_b_sel`, `add_sub_sel` (ALU control)
- `jump_flag`, `jump_addr` (PC control)

In Vivado, right-click the signals in the Objects pane and choose
"Add to Wave Window".

---

## 12. Integration notes for the rest of the team

Read this carefully — these are the assumptions the decoder makes about
the rest of the datapath. If a teammate's module uses the opposite
polarity of any signal, *one* of the modules has to change.

### 12.1 Register Bank

- `reg_en_sel(2:0)` drives the **address input** of your 3-to-8 decoder
  (the one inside the register bank).
- `reg_write_en` drives the **enable input** of that 3-to-8 decoder.
  When low, the 3-to-8 decoder must drive all 8 of its outputs to 0.
  *If* your existing 3-to-8 decoder has no enable, add one — it's a
  3-gate change (just AND every output with the enable line).
- R0 must be hardwired to constant `0000` regardless of writes; it is
  the read-only zero register that NEG and JZR rely on.

### 12.2 Data-bus mux (2-way 4-bit)

- `load_sel = '1'` ⇒ select the **immediate** side (`imm_val`).
- `load_sel = '0'` ⇒ select the **ALU output** side.
- If your mux uses the opposite polarity, invert `load_sel` *in the
  mux*, not in the decoder — the decoder's polarity is the one named in
  this README.

### 12.3 ALU

- `add_sub_sel = '0'` ⇒ add (`A + B`).
- `add_sub_sel = '1'` ⇒ subtract (`A − B`).
- For NEG and JZR, the decoder relies on the ALU computing exactly
  `A − B` and exactly `A + B` respectively. If your ALU instead computes
  `B − A`, NEG will produce `R` instead of `−R` and we will spend an
  afternoon debugging.

### 12.4 8-way 4-bit muxes

- The **left** mux's output must be wired back into the decoder's
  `reg_check_val` input. This is the mux selected by `mux_a_sel`.
- This is the wire labelled "Register check for jump" in Fig. 1.
- The right mux's output goes only to the ALU's B input — the decoder
  does not need to see it.

### 12.5 Program Counter / PC-source mux

- `jump_flag = '1'` ⇒ load PC with `jump_addr`.
- `jump_flag = '0'` ⇒ load PC with PC+1 from the 3-bit adder.
- The reset input of the PC's flip-flops must be tied to the same
  pushbutton that resets the register bank, so both come up clean.

---

## 13. Common pitfalls and FAQ

### Q: "I see latches inferred. Did the decoder grow state?"

A: No. The dataflow architecture in this file assigns every output
unconditionally. If Vivado warns about latches, it's almost certainly in
**another** module, not this one. Double-check that the warning's source
location is not this file.

### Q: "MOVI R0 — what happens?"

A: The 3-to-8 decoder enables R0's clock input, but R0 has no
flip-flops; its output is the constant `0000`. The write is silently
discarded. This is the lab's intended behaviour and Test #3 in the unit
testbench verifies the decoder produces the correct control signals
even for this nonsensical-but-legal instruction.

### Q: "Why is `imm_val` driven even on non-MOVI cycles?"

A: Because it's just a slice of the instruction (`I[3:0]`). We don't
gate it because the 2-way 4-bit data-bus mux ignores its immediate input
when `load_sel = '0'`. Adding a gate would cost more than it saves.

### Q: "Why is `jump_addr` driven even on non-JZR cycles?"

A: Same reason — it's a slice of the instruction (`I[2:0]`). The
PC-source mux ignores it whenever `jump_flag = '0'`.

### Q: "Could we use the ALU's `Zero` output for JZR instead of a separate detector?"

A: Yes, and it would even save the 4-input NOR inside the decoder. But
it would add a wire from the ALU back into the decoder, plus a
combinational dependency between two modules that are otherwise
independent. We chose to keep the zero detector inside the decoder for
modularity. If the team wants to extra-credit-optimise gate count, this
is the first place to look.

### Q: "Why dataflow VHDL instead of a process with a case statement?"

A: Two reasons:
1. **No latch risk.** Every output is assigned unconditionally exactly
   once. Process+case relies on either a default block or assigning every
   signal in every branch, which is easy to forget.
2. **Auditable gate count.** The lab's Step 1 says explicitly: *"Before
   they even touch Vivado, they should map out the logic for each output
   pin on a piece of paper."* The dataflow style **is** that paper
   diagram, written verbatim in VHDL. Easy to defend in the demo.

### Q: "What if I want to add a 5th instruction?"

A: The opcode field is only 2 bits (4 codes), so all four codes are
already used. To add a 5th instruction you'd need either to widen the
opcode (which means 11-bit instructions become 13-bit, and Program ROM /
Instruction Bus widen) or to "steal" some unused encoding space inside
an existing opcode (e.g. use `JZR R, d` with some specific R or d value
as a different instruction). Both are extra-credit territory under the
"creative designs" category in Step 5 of the lab.

### Q: "What if `instruction` is `XXXX...` at simulation start?"

A: The opcode one-hot decoder will produce `X` for all four `is_*`
signals, and downstream outputs will be `X`. This is harmless — the
testbenches start with `wait for 100 ns;` to let the inputs settle into
real values before evaluating any assertion.

---

## 14. Files in this project

```
InstructionDecoder/
├── README.md                                         <- this file
├── InstructionDecoder.xpr                            Vivado project file
└── InstructionDecoder.srcs/
    ├── sources_1/new/instruction_decoder.vhd        the decoder (RTL)
    └── sim_1/new/
        ├── instruction_decoder_tb.vhd               unit testbench (assertions)
        └── decoder_tb.vhd                           system trace of Step-4 program
```

| File | What's in it |
| --- | --- |
| [instruction_decoder.vhd](InstructionDecoder.srcs/sources_1/new/instruction_decoder.vhd) | The combinational decoder, dataflow style with explicit Boolean equations. Approximately 21 basic gates plus a NOR4. No process, no latch risk. |
| [instruction_decoder_tb.vhd](InstructionDecoder.srcs/sim_1/new/instruction_decoder_tb.vhd) | Self-checking unit testbench with 10 cases covering all 4 opcodes, corner registers, corner immediates, and both branches of JZR. |
| [decoder_tb.vhd](InstructionDecoder.srcs/sim_1/new/decoder_tb.vhd) | System-style trace driving the decoder with the exact 12-bit machine-code words of the Step-4 sum-of-1..3 program. |

---

## Final checklist before the demo

- [ ] Both testbenches simulate clean (no `Failure` / `Error` in Tcl console).
- [ ] The Step-4 program in `decoder_tb.vhd` matches the program your
      Program-ROM teammate has hard-coded.
- [ ] `reg_check_val` is wired to the **left** 8-way 4-bit mux's output
      in the top-level design.
- [ ] `reg_write_en` is wired to the **enable** of the register bank's
      3-to-8 decoder, not to a register's clock-enable directly.
- [ ] The ALU computes `A − B` (not `B − A`) when `add_sub_sel = '1'`.
- [ ] Reset pushbutton is tied to both PC reset and register-bank reset.
- [ ] R0 is hardwired to `0000`.
- [ ] Slow clock is wired to the PC and register bank (~2-3 sec/tick),
      not to anything in this decoder (the decoder is combinational).