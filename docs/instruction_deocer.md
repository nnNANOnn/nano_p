# < INSTRUCTION DECODER >

## INTRODUCTION
The Instruction Decoder is the brain of your nano-processor. It takes a 12-bit binary command from the Program ROM and translates it into control signals that tell every other component (Registers, ALU, Muxes) exactly what to do at that specific moment.

< THE 12-bit INTRUCTION FORMAT >
Every instruction is 12 bits long. The decoder splits these bits into specific "fields": 
-	Opcode (Bits 11-10): The first two bits define the operation type (00=ADD, 01=NEG, 10=MOVI, 11=JZR). 
-	Register A / Destination (Bits 9-7): Usually defines which register is being modified or checked. 
-	Register B (Bits 6-4): Used in the ADD instruction to select the second operand. 
-	Immediate Value / Address (Bits 3-0): Provides a constant number (for MOVI) or a target line number (for JZR). 


## HOW EACH INSTRUCTION EXECUTE
1. MOVI R, d (Move Immediate)
Logic: $R \leftarrow d$
Binary Format: 10 RRR 000 dddd
-	Opcode Detection: The decoder sees 10 at bits 11-10 and identifies this as a "Load" operation. 
-	Load Select (load_sel): This is the most important signal for this instruction. The decoder sets it to 1. In Figure 1, you can see this control signal goes to a 2-way 4-bit Mux. A '1' tells that Mux to ignore the ALU output and instead grab the 4-bit Immediate value directly from the instruction bus. 
-	Targeting the Register: The decoder takes bits 9-7 ($RRR$) and passes them to reg_en_sel. This goes to the 3-to-8 decoder inside the Register Bank, which "highlights" the specific register you want to update. 
-	Execution: Finally, reg_write_en is set to 1, allowing the immediate value ($dddd$) to be written into register $R$ on the next clock pulse. 


2. ADD Ra, Rb (Addition)
Logic: $Ra \leftarrow Ra + Rb$
Binary Format: 00 RaRaRa RbRbRb 0000
-	Opcode Detection: The decoder sees 00. 
-	Mux Selection: The decoder sets mux_a_sel to $Ra$ (bits 9-7) and mux_b_sel to $Rb$ (bits 6-4). This tells the two 8-way 4-bit Muxes to pull values out of those two registers and place them on the inputs of the 4-bit Add/Sub Unit. 
-	ALU Operation: The decoder sets add_sub_sel to 0. This tells the Add/Sub unit to perform an Addition. 
-	The Loopback: The decoder sets load_sel to 0. This tells the input Mux to take the result coming out of the ALU and feed it back into the Register Bank. 
-	Storage: reg_write_en is set to 1, and the new sum is stored back into $Ra$. 


3. NEG R (2's Complement)
Logic: $R \leftarrow -R$ (Calculated as $0 - R$)
Binary Format: 01 RRR 0000000
-	Opcode Detection: The decoder sees 01. 
-	The "Zero" Trick: The Nanoprocessor doesn't have a dedicated "Negate" gate. Instead, it uses subtraction. The decoder hardwires mux_a_sel to 000. Since Register 0 (R0) is hardcoded to be all zeros, the first input to the ALU is now 0. 
-	Selecting the Operand: The decoder sets mux_b_sel to $RRR$ (bits 9-7), putting the value of register $R$ on the second ALU input. 
-	ALU Operation: The decoder sets add_sub_sel to 1. This tells the unit to perform Subtraction ($0 - R$). 
-	Storage: Like the ADD instruction, load_sel is 0 (ALU path), and reg_write_en is 1 to save the negative result back into register $R$. 


4. JZR R, d (Jump if Zero)
Logic: If R == 0 then PC = d else PC = PC + 1
Binary Format: 11 RRR 000 0ddd
-	Opcode Detection: The decoder sees 11. 
-	Safety First: reg_write_en is set to 0. We are only checking a value, not changing it, so we must make sure no registers are accidentally overwritten. 
-	The Check: The decoder sets mux_a_sel to $RRR$ (bits 9-7). This pulls the value of register $R$ out of the Register Bank and sends it to the decoder through the reg_check_val bus (labeled "Register check for jump" in Figure 1). 
-	Internal Decision: Inside the decoder's VHDL process, an if statement checks if reg_check_val is exactly "0000". 
-	Directing the Program Counter (PC):
    +	If Zero: jump_flag becomes 1. This tells the 2-way 3-bit Mux near the Program Counter to select the Address to jump ($ddd$ from bits 2-0). 
    +	If Not Zero: jump_flag is 0. The Mux selects the output of the 3-bit Adder, which is simply the current address plus one ($PC + 1$)

## THE "TINY DETAILS" THAT MATTER
-	Defaulting: At the very top of the VHDL process, we assign every output a "default" value (like reg_write_en <= '0'). This ensures that if an instruction doesn't need to write to a register, the signal stays off. Without this, your code might create "Latches," which are unstable in hardware. 
-	Sensitivity List: The process watches both instruction and reg_check_val. This means the moment the register value changes (like $R1$ becoming $0$), the decoder instantly updates the jump_flag without waiting for a clock cycle.
-	Register 0 (R0): Remember that R0 is read-only and always zero. This is why the NEG instruction works so simply—it relies on this "constant zero" to perform subtraction. 
By managing these signals, your Instruction Decoder ensures that data flows through the right "pipes" (buses) and hits the right "valves" (muxes) at the exact right time. 


