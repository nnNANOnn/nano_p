# Program ROM — `Program_Rom.vhd`

> The instruction memory of the nanoprocessor. 8 hard-coded 12-bit
> machine words, one per address from `0` to `7`, that together
> compute the sum 1 + 2 + 3 and leave the result in R7.

---

## 1. Structure

```vhdl
entity Program_ROM is
    Port (
        ROM_address : in  instruction_address;   -- 3-bit PC value (0..7)
        I           : out instruction_bus        -- 12-bit instruction
    );
end Program_ROM;
```

The body is a constant array indexed by the PC. There is no clock and
no state — Program ROM is purely combinational. (It synthesises into a
4-input LUT cluster on the Artix-7 fabric.)

```vhdl
constant ROM_CONTENTS : rom_type := (
    0 => "101110000000",   -- MOVI R7, 0
    1 => "100010000011",   -- MOVI R1, 3
    2 => "100100000001",   -- MOVI R2, 1
    3 => "010100000000",   -- NEG  R2
    4 => "001110010000",   -- ADD  R7, R1
    5 => "000010100000",   -- ADD  R1, R2
    6 => "110010000110",   -- JZR  R1, 6
    7 => "110000000100"    -- JZR  R0, 4
);

I <= ROM_CONTENTS(to_integer(unsigned(ROM_address)));
```

---

## 2. What changed from the old version

The previous version had two problems:

1. **Address width mismatch.** `ROM_address` was 4 bits wide (16
   entries), but the PC is 3 bits. The fix narrows the address to
   `instruction_address` (3 bits) and shrinks the array to 8 entries.
2. **Misleading opcode comments.** The header said opcodes were 3 bits
   (`000=ADD, 001=NEG, 010=NEG, 100=MOVI, 101=MOVI, 110=JZR, 111=MUL`)
   while the *actual binary contents* used the correct 2-bit opcodes
   from Table 1 of the lab. The fix rewrites the comments to match the
   real encoding (`00=ADD, 01=NEG, 10=MOVI, 11=JZR`).

The program itself was also tidied: `R7` now starts at `0` (rather than
`3`), so the program reads cleanly as `sum := 0; for i = 3..1: sum +=
i`, which is what the lab asks for.

---

## 3. Encoding cheat sheet

For convenience, here is the bit layout of all four instructions.
`R`, `Ra`, `Rb` ∈ `[0,7]`, encoded as 3 bits in MSB-first order.

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

---

## 4. Program walkthrough

```
addr  asm              binary                comment
 0    MOVI R7, 0       10 111 000 0000       sum := 0
 1    MOVI R1, 3       10 001 000 0011       ctr := 3 (counts down)
 2    MOVI R2, 1       10 010 000 0001       tmp := 1
 3    NEG  R2          01 010 000 0000       tmp := -1   (1111 in 2's complement)
 4    ADD  R7, R1      00 111 001 0000       sum += ctr  (the actual addition)
 5    ADD  R1, R2      00 001 010 0000       ctr -= 1    (R1 += R2, R2 = -1)
 6    JZR  R1, 6       11 001 000 0110       halt: jump to self if ctr=0
 7    JZR  R0, 4       11 000 000 0100       R0 always 0 -> unconditional jump to 4
```

### 4.1 Cycle-by-cycle trace

```
PC=0  R7 ← 0
PC=1  R1 ← 3
PC=2  R2 ← 1
PC=3  R2 ← -1
PC=4  R7 ← 0 + 3 = 3
PC=5  R1 ← 3 + (-1) = 2
PC=6  R1 = 2 ≠ 0 → no jump → PC=7
PC=7  jump to 4 (R0 = 0 always) → PC=4
PC=4  R7 ← 3 + 2 = 5
PC=5  R1 ← 2 + (-1) = 1
PC=6  R1 = 1 ≠ 0 → PC=7
PC=7  jump → PC=4
PC=4  R7 ← 5 + 1 = 6     ← FINAL ANSWER (1+2+3 = 6 ✓)
PC=5  R1 ← 1 + (-1) = 0
PC=6  R1 = 0 → jump to 6 → PC=6  (self-loop, halt)
```

### 4.2 The two cleverness tricks

**Halt via self-jump.** The ISA has no `HALT` instruction. We use
`JZR R1, 6` *at* address 6: once R1 = 0, the JZR keeps firing and
parking the PC at the same address. R7 is not touched, so the result
stays visible.

**Unconditional back-edge.** Address 7 is `JZR R0, 4`. Because R0 is
hardwired to `0000`, this `JZR` *always* fires — effectively turning
`JZR` into an unconditional branch. (Exactly the same trick MIPS uses
with `BEQ $zero, $zero, label`.)

### 4.3 Why the program fits in exactly 8 instructions

The PC is 3 bits → ROM has 8 slots. We use every one of them.
Compressing further would require extending the ISA, e.g. adding a
real unconditional `JMP` (would let us drop instruction 7) or adding
`SUBI R, d` (would let us drop the NEG + ADD pair into a single
instruction). Both are extra-credit territory under "creative designs"
(Step 5 of the lab).

---

## 5. Editing the program

To run a different program:

1. Compute the 12-bit machine code for each instruction using the
   encoding cheat sheet above.
2. Replace the strings in the `ROM_CONTENTS` constant inside
   `Program_Rom.vhd`.
3. Rebuild the bitstream. (No other file needs changing — Program ROM
   is the only place the program lives.)

If you need more than 8 instructions, the PC has to grow. Widen
`instruction_address` and `register_address` in `packages/buses.vhd`
(they are independent subtypes — only the PC needs to grow), enlarge
`PC_Inc`'s `RCA_3` to a wider RCA, and bump the ROM array bound.
