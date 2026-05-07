# Program Counter — `PC` and `PC_Inc`

> Sequential and combinational halves of the program-counter logic.
> Together with the 2-way 3-bit `Mux_2_3` they implement the entire
> control-flow apparatus shown at the bottom of Fig. 1 of the lab.

---

## 1. Role in the nanoprocessor

The PC is the only sequential element on the instruction-fetch side.
Every slow-clock cycle:

1. The current PC value `M(2:0)` indexes Program ROM.
2. `PC_Inc` combinationally produces `M + 1`.
3. The PC-source mux (a `Mux_2_3` instance) picks between `M + 1` and
   `jump_addr`, gated by the decoder's `jump_flag`.
4. On the next rising slow-clock edge, the chosen value loads back into
   the PC register.

When `Reset_Btn = '1'` (asynchronously asserted by BTNC on the Basys 3),
all three flip-flops in the PC clear to `0`, restarting the program at
address 0.

---

## 2. `PC` (the 3-bit register)

Implemented as one `Reg generic map (N => 3)` instance, hard-wired to
always-enabled (`En = '1'`).

```vhdl
Reg_0 : entity work.Reg
    generic map (N => 3)
    port map (
        D   => A,
        Res => Res,
        En  => '1',
        Clk => Clk,
        Q   => M
    );
```

| Port | Width | Description |
|---|---|---|
| `A`   | 3 | next-PC value (output of the PC-source mux) |
| `Res` | 1 | async reset, tied to `Reset_Btn` |
| `Clk` | 1 | slow clock from `Clock_Divider` |
| `M`   | 3 | current PC, drives Program ROM and `PC_Inc` |

### 2.1 Bug fixes from the original file

The previous version instantiated `Reg` with the older "labeled
component" syntax but never declared `Reg` as a component, which would
fail at elaboration. The fix uses **direct entity instantiation**
(`entity work.Reg`) — cleaner and free of component/entity mismatch.

---

## 3. `PC_Inc` (the +1 incrementer)

A 3-bit Ripple Carry Adder with `B` hard-wired to `"001"` and `C_in`
hard-wired to `'0'`. Pure combinational, zero state.

```vhdl
Add : RCA_3
    port map (
        A     => A_in,
        B     => "001",
        C_in  => '0',
        S     => A_out,
        C_out => open
    );
```

| Port | Width | Description |
|---|---|---|
| `A_in`  | 3 | current PC |
| `A_out` | 3 | PC + 1 |

### 3.1 Wrap-around behaviour

`C_out` is intentionally left **open**. With a 3-bit PC, the address
space is `0..7`; once `PC = 7`, `PC + 1` overflows to `0`. We do not
need the carry-out because:

* On the lab's Step-4 program, address 7 is `JZR R0, 4`, which always
  jumps before `PC + 1` is ever used. So the wrap-around never triggers.
* Even if a different program *did* fall off the end, wrapping silently
  to address 0 is the simplest defined behaviour.

### 3.2 Bug fix from the original file

The previous version omitted the `C_out` mapping entirely, which strict
VHDL rejects. The fix lists `C_out => open` explicitly.

---

## 4. Tying it all together (top-level wiring)

In `Nanoprocessor.vhd`:

```vhdl
pc_inst    : entity work.PC      port map (A => PC_next, ..., M => PC_curr);
pc_inc_inst: entity work.PC_Inc  port map (A_in => PC_curr, A_out => PC_plus1);
pc_src_mux : entity work.Mux_2_3 port map (S => jump_flag,
                                           D0 => PC_plus1,
                                           D1 => jump_addr,
                                           Y  => PC_next);
```

This forms the closed loop: `PC_curr → PC_plus1 →(mux)→ PC_next → PC_curr+1`.

---

## 5. Expected timing diagram

For the Step-4 program, the PC sequence is:

```
0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 4 → 5 → 6 → 7 → 4 → 5 → 6 → 6 → 6 → ...
```

After the third pass through the loop, `JZR R1, 6` jumps to itself and
the PC parks at 6 indefinitely. R7 stays at the final answer (6).
