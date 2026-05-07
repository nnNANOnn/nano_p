# Instruction Decoder — `instruction_decoder.vhd`

> The control unit of the nanoprocessor: a single combinational block
> that converts the 12-bit instruction word into every datapath
> control signal in one sweep. No clock, no state, no latches.

---

## 1. What it is

`instruction_decoder.vhd` is **purely combinational** logic. It takes:

* `instruction(11..0)` — the current instruction word from Program ROM
* `reg_check_val(3..0)` — the 4-bit value of the register currently
  routed through Mux A (used only by `JZR` to detect zero)

…and emits ten control wires that the rest of the datapath consumes:

| Output | Width | Goes to |
|---|---|---|
| `reg_en_sel` | 3 | Address input of the register bank's 3-to-8 decoder |
| `reg_write_en` | 1 | Enable input of that 3-to-8 decoder |
| `load_sel` | 1 | Select line of the 2-way 4-bit data-bus mux |
| `imm_val` | 4 | Immediate input of the data-bus mux |
| `mux_a_sel` | 3 | Select line of the left 8-way 4-bit mux (ALU operand A) |
| `mux_b_sel` | 3 | Select line of the right 8-way 4-bit mux (ALU operand B) |
| `add_sub_sel` | 1 | ALU's add/sub select |
| `jump_flag` | 1 | Select line of the 2-way 3-bit PC-source mux |
| `jump_addr` | 3 | Jump target (low 3 bits of `d`) |

---

## 2. Instruction set

| `I[11:10]` | Mnemonic | Effect |
|---|---|---|
| `00` | `ADD Ra, Rb` | `Ra ← Ra + Rb` |
| `01` | `NEG R`      | `R  ← −R` |
| `10` | `MOVI R, d`  | `R  ← d` |
| `11` | `JZR R, d`   | if `R == 0` then `PC ← d` else `PC ← PC + 1` |

Bit layout:

```
bit:        11 10  9  8  7  6  5  4  3  2  1  0
MOVI R, d : │ 1│ 0│ R│ R│ R│ 0│ 0│ 0│ d│ d│ d│ d│
ADD Ra,Rb : │ 0│ 0│Ra│Ra│Ra│Rb│Rb│Rb│ 0│ 0│ 0│ 0│
NEG  R    : │ 0│ 1│ R│ R│ R│ 0│ 0│ 0│ 0│ 0│ 0│ 0│
JZR  R, d : │ 1│ 1│ R│ R│ R│ 0│ 0│ 0│ 0│ d│ d│ d│
```

Two layout coincidences let us delete hardware:

1. Bits `I[6:4]` are `000` for every instruction *except* `ADD`. So
   `mux_b_sel` can stay wired to `I[6:4]` for `MOVI`/`JZR` and
   naturally select R0 — no extra mux.
2. The destination register is always `I[9:7]` for the three writing
   instructions. For `JZR`, `reg_write_en = 0` blocks the write, so
   the value of `reg_en_sel` is don't-care and we leave it wired to
   `I[9:7]` (a piece of wire, 0 gates).

---

## 3. Truth table

| `op` | `is_ADD` | `is_NEG` | `is_MOVI` | `is_JZR` | `reg_write_en` | `load_sel` | `add_sub_sel` | `mux_a_sel` | `mux_b_sel` | `jump_flag` |
|---|---|---|---|---|---|---|---|---|---|---|
| `00` (ADD)  | 1 | 0 | 0 | 0 | **1** | 0 | 0 | I(9:7) (Ra) | I(6:4) (Rb) | 0 |
| `01` (NEG)  | 0 | 1 | 0 | 0 | **1** | 0 | **1** | **`000`** (R0) | I(9:7) (R) | 0 |
| `10` (MOVI) | 0 | 0 | 1 | 0 | **1** | **1** | X | X | X | 0 |
| `11` (JZR)  | 0 | 0 | 0 | 1 | **0** | X | X | I(9:7) (R) | I(6:4)=`000` (R0) | `R==0` |

* **NEG: A = 0, B = R, sub.** ALU computes `A − B = 0 − R = −R`. If
  we did A=R, B=0 we would compute `R − 0 = R` (the identity, wrong).
* **JZR: A = R, B = 0, add.** ALU computes `R + 0 = R`. We don't
  *write* that result, but `Mux_A_out` is fed back into the decoder
  as `reg_check_val`, where the 4-input NOR detects zero.

---

## 4. Boolean equations

```
op1 = I(11),  op0 = I(10)

is_ADD  = ¬op1 · ¬op0
is_NEG  = ¬op1 ·  op0
is_MOVI =  op1 · ¬op0
is_JZR  =  op1 ·  op0

reg_en_sel    = I(9..7)        -- WIRE
imm_val       = I(3..0)        -- WIRE
jump_addr     = I(2..0)        -- WIRE

reg_write_en  = ¬is_JZR
load_sel      = is_MOVI
add_sub_sel   = is_NEG

mux_a_sel(i)  = I(i+7) · ¬is_NEG               for i in {0,1,2}
mux_b_sel(i)  = (I(i+7) · is_NEG)
              + (I(i+4) · ¬is_NEG)             for i in {0,1,2}

r_is_zero     = ¬(rcv(3) ∨ rcv(2) ∨ rcv(1) ∨ rcv(0))
jump_flag     = is_JZR · r_is_zero
```

Total gate budget (rough count, 2-input gates unless noted):

| Stage | Gates |
|---|---|
| Opcode one-hot decode | ~6 |
| `reg_write_en`, `load_sel`, `add_sub_sel` | 1 (the NOT) |
| `mux_a_sel` (3 bits) | 4 |
| `mux_b_sel` (3 bits) | 9 |
| Zero detector | 1 NOR4 |
| `jump_flag` | 1 AND2 |
| **Total** | **~21 basic gates + 1 NOR4** |

Quote that number during the demo for the "least-gates" extra-credit
category in Step 5 of the lab.

---

## 5. Walk-through of every instruction

### 5.1 `MOVI R, d`
Datapath: `imm_val → data-bus mux (load_sel=1) → Data Bus → register R`.

### 5.2 `ADD Ra, Rb`
Datapath: `Mux_A=Ra, Mux_B=Rb → ALU adds → data-bus mux (load_sel=0) → Ra`.

### 5.3 `NEG R`
Datapath: `Mux_A=R0=0, Mux_B=R → ALU subtracts (0−R = −R) → R`.

### 5.4 `JZR R, d`
Datapath: `Mux_A=R → reg_check_val → 4-input NOR → AND with is_JZR → jump_flag`.
If `jump_flag = '1'`, the PC-source mux selects `jump_addr`; otherwise
`PC + 1` from the 3-bit adder.

---

## 6. Why dataflow VHDL?

Two reasons we did not use a `process` with a `case` statement:

1. **No latch risk.** Every output is assigned unconditionally exactly
   once. A process-and-case relies on either a default block or
   assigning every signal in every branch — easy to forget, easy to
   create unintentional latches.
2. **Auditable gate count.** The lab's Step 1 says explicitly: *"Before
   you even touch Vivado, map out the logic for each output pin on a
   piece of paper."* The dataflow style **is** that paper diagram,
   written verbatim in VHDL.

---

## 7. Testbench

`sim/instruction_decoder_tb.vhd` exercises 10 cases:

| # | Case | Verifies |
|---|---|---|
| 1 | `MOVI R1, 10` | Basic MOVI |
| 2 | `MOVI R7, 15` | Highest register, max immediate |
| 3 | `MOVI R0, 0` | Lowest register, min immediate |
| 4 | `ADD R1, R2` | Basic ADD |
| 5 | `ADD R7, R6` | Top two registers |
| 6 | `NEG R2` | mux A = R0, mux B = R, sub asserted |
| 7 | `JZR R1, 7` with R1 ≠ 0 | Jump NOT taken |
| 8 | `JZR R1, 7` with R1 = 0 | Jump TAKEN |
| 9 | `JZR R0, 3` | R0 always 0 ⇒ jump always taken |
| 10 | Each bit of `reg_check_val` | Zero detector is a real 4-input NOR |

---

## 8. Integration assumptions

The decoder makes the following assumptions about the rest of the
datapath. If a teammate's module disagrees, change *the other module*
to match — these polarities are referenced everywhere else in the docs.

* **Register Bank**: `reg_en_sel` is the address input of the bank's
  3-to-8 decoder. `reg_write_en` is the enable. R0 is hardwired to 0.
* **Data-bus mux**: `load_sel = '1'` ⇒ immediate side; `'0'` ⇒ ALU.
* **ALU**: `add_sub_sel = '1'` ⇒ `A − B` (not `B − A`).
* **8-way 4-bit muxes**: Mux A's output must be wired back into the
  decoder's `reg_check_val` input.
* **PC-source mux**: `jump_flag = '1'` ⇒ load `jump_addr`; `'0'` ⇒
  load `PC + 1`.
* **Reset**: PC and Register Bank share the same reset pushbutton.

These are all satisfied in `Nanoprocessor.vhd` — see `nanoprocessor.md`.
