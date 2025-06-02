# MAK-8 Instruction Set Architecture (ISA)

## Overview

MAK-8 is an 8-bit RISC processor with 16-bit instructions. This document defines the complete instruction set architecture, including instruction formats, opcodes, and operational semantics.

## Architecture Summary

- **Data Width**: 8 bits
- **Instruction Width**: 16 bits
- **Address Space**: 16-bit (64K words for instructions, 64K bytes for data)
- **Registers**: 8 general-purpose registers (R0-R7), where R0 is hardwired to 0
- **Architecture Type**: Harvard (separate instruction and data memory)
- **Endianness**: Little-endian

## Register Set

| Register | Description |
|----------|-------------|
| R0 | Always 0 (hardwired) |
| R1-R7 | General purpose 8-bit registers |
| PC | Program Counter (16-bit) |
| FLAGS | Status register (Zero, Carry, Negative) |

## Instruction Formats

MAK-8 uses three instruction formats to maximize efficiency:

### Format A: Register-Register (R-Type)
```
15 14 13 12 | 11 10 9 | 8 7 6 | 5 4 3 | 2 1 0
  OPCODE    |   RD    |  RS1  |  RS2  | FUNC
   (4 bits) | (3 bits)|(3 bits)|(3 bits)|(3 bits)
```

### Format B: Register-Immediate (I-Type)
```
15 14 13 12 | 11 10 9 | 8 7 6 | 5 4 3 2 1 0
  OPCODE    |   RD    |  RS1  |   IMMEDIATE
   (4 bits) | (3 bits)|(3 bits)|   (6 bits)
```

### Format C: Branch/Jump (B-Type)
```
15 14 13 12 | 11 10 9 | 8 7 6 | 5 4 3 2 1 0
  OPCODE    |  COND   |  RS1  |   OFFSET
   (4 bits) | (3 bits)|(3 bits)|   (6 bits)
```

### Format D: Load/Store (M-Type)
```
15 14 13 12 | 11 10 9 | 8 7 6 | 5 4 3 2 1 0
  OPCODE    |  RD/RS  |  RB   |   OFFSET
   (4 bits) | (3 bits)|(3 bits)|   (6 bits)
```

## Instruction Set

### Arithmetic and Logic Instructions (R-Type)

| Mnemonic | Opcode | Func | Operation | Description |
|----------|--------|------|-----------|-------------|
| ADD | 0000 | 000 | RD = RS1 + RS2 | Add two registers |
| SUB | 0000 | 001 | RD = RS1 - RS2 | Subtract RS2 from RS1 |
| AND | 0000 | 010 | RD = RS1 & RS2 | Bitwise AND |
| OR  | 0000 | 011 | RD = RS1 \| RS2 | Bitwise OR |
| XOR | 0000 | 100 | RD = RS1 ^ RS2 | Bitwise XOR |
| NOT | 0000 | 101 | RD = ~RS1 | Bitwise NOT (RS2 ignored) |
| SHL | 0000 | 110 | RD = RS1 << RS2[2:0] | Shift left by RS2 bits |
| SHR | 0000 | 111 | RD = RS1 >> RS2[2:0] | Shift right by RS2 bits |

### Immediate Instructions (I-Type)

| Mnemonic | Opcode | Operation | Description |
|----------|--------|-----------|-------------|
| ADDI | 0001 | RD = RS1 + IMM | Add immediate (sign-extended) |
| SUBI | 0010 | RD = RS1 - IMM | Subtract immediate |
| ANDI | 0011 | RD = RS1 & IMM | AND with immediate |
| ORI  | 0100 | RD = RS1 \| IMM | OR with immediate |
| XORI | 0101 | RD = RS1 ^ IMM | XOR with immediate |
| LUI  | 0110 | RD = IMM << 2 | Load upper immediate |

### Memory Instructions (M-Type)

| Mnemonic | Opcode | Operation | Description |
|----------|--------|-----------|-------------|
| LDB | 0111 | RD = MEM[RB + OFFSET] | Load byte from memory |
| STB | 1000 | MEM[RB + OFFSET] = RS | Store byte to memory |

### Branch Instructions (B-Type)

| Mnemonic | Opcode | Cond | Operation | Description |
|----------|--------|------|-----------|-------------|
| BEQ | 1001 | 000 | if(RS1 == 0) PC += OFFSET | Branch if equal to zero |
| BNE | 1001 | 001 | if(RS1 != 0) PC += OFFSET | Branch if not equal to zero |
| BLT | 1001 | 010 | if(RS1 < 0) PC += OFFSET | Branch if less than zero |
| BGE | 1001 | 011 | if(RS1 >= 0) PC += OFFSET | Branch if greater or equal to zero |
| JMP | 1001 | 100 | PC += OFFSET | Unconditional jump (RS1 ignored) |
| JAL | 1001 | 101 | RD = PC+1; PC += OFFSET | Jump and link |

### Special Instructions

| Mnemonic | Opcode | Operation | Description |
|----------|--------|-----------|-------------|
| NOP | 1111 | No operation | No operation (all fields ignored) |
| HLT | 1110 | Halt execution | Stop the processor |

## Instruction Encoding Examples

### Example 1: ADD R3, R1, R2
```
Format: R-Type
Binary: 0000 011 001 010 000
Hex: 0x0648
```

### Example 2: ADDI R4, R2, 15
```
Format: I-Type
Binary: 0001 100 010 001111
Hex: 0x190F
```

### Example 3: BEQ R5, -8
```
Format: B-Type
Binary: 1001 000 101 111000
Hex: 0x92F8
```

### Example 4: LDB R6, R3, 10
```
Format: M-Type
Binary: 0111 110 011 001010
Hex: 0x7CCA
```

## Assembly Language Conventions

### Syntax Rules
1. Instructions are case-insensitive
2. Registers are prefixed with 'R' (R0-R7)
3. Immediate values can be decimal or hexadecimal (0x prefix)
4. Comments start with ';' or '//'

### Pseudo-Instructions
These are convenience instructions that assemble to real instructions:

| Pseudo | Actual Instruction | Description |
|--------|-------------------|-------------|
| MOV RD, RS | ADD RD, RS, R0 | Move register to register |
| LI RD, IMM | ADDI RD, R0, IMM | Load immediate |
| CLR RD | XOR RD, RD, RD | Clear register |
| INC RD | ADDI RD, RD, 1 | Increment register |
| DEC RD | SUBI RD, RD, 1 | Decrement register |
| BR OFFSET | JMP OFFSET | Unconditional branch |

## Programming Model

### Status Flags
- **Zero (Z)**: Set when result is zero
- **Carry (C)**: Set on arithmetic carry/borrow
- **Negative (N)**: Set when result MSB is 1

### Memory Map
```
0x0000-0x7FFF: ROM (Program Memory) - 32K words
0x8000-0xFFFF: RAM (Data Memory) - 32K bytes
```

### Interrupt Model
Currently not implemented in basic version.

## Design Rationale

1. **16-bit instructions**: Provides enough bits for encoding while keeping decoder simple
2. **8 registers**: Balance between programming flexibility and hardware cost
3. **R0 = 0**: Simplifies many operations and provides a constant zero source
4. **6-bit immediate**: Covers common small constants (-32 to +31 signed)
5. **Harvard architecture**: Allows simultaneous instruction fetch and data access
6. **RISC philosophy**: Simple instructions that execute in one cycle

## Example Programs

### 1. Computing Sum of Array
```assembly
; Sum 10 bytes starting at address 0x100
; Result in R3

    LI   R1, 10      ; Counter
    LI   R2, 0       ; Base address (will add 0x100)
    ADDI R2, R2, 0x40 ; Split loading due to 6-bit immediate
    ADDI R2, R2, 0x40 ; R2 = 0x100 (alternative: use LUI)
    CLR  R3          ; Sum = 0

loop:
    LDB  R4, R2, 0   ; Load byte at [R2]
    ADD  R3, R3, R4  ; Add to sum
    INC  R2          ; Next address
    DEC  R1          ; Decrement counter
    BNE  R1, loop    ; Loop if counter != 0

    HLT              ; Done
```

### 2. Factorial Calculation
```assembly
; Calculate factorial of number in R1
; Result in R2

    LI   R2, 1      ; Result = 1
    
fact_loop:
    BEQ  R1, done   ; If n == 0, done
    MOV  R3, R2     ; Save current result
    CLR  R4         ; Counter for multiplication
    
mult_loop:
    ADD  R2, R2, R3 ; Repeated addition
    INC  R4
    BNE  R4, R1, mult_loop
    
    DEC  R1         ; n--
    BR   fact_loop
    
done:
    HLT
```

## Future Extensions

1. **Multiplication/Division**: Hardware multiply unit
2. **Interrupts**: Basic interrupt support with vector table
3. **Stack Operations**: Push/Pop instructions
4. **Indirect Addressing**: Register indirect modes
5. **Compare Instructions**: Dedicated comparison without modification
