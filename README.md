# MAK-8: Manikanta's Architechture Kit – 8-bit RISC CPU

**MAK-8** is a fully custom-designed 8-bit **RISC-style CPU core** built from scratch using **SystemVerilog** and designed to run on the **Digilent Nexys A7 (Artix-7)** FPGA. It is educational, minimal, and modular – perfect for learning how CPUs actually work.

---

## 🔧 Features

- 8-bit datapath and instruction width
- 8 general-purpose registers (R0–R7)
- Custom RISC-style ISA with:
  - Arithmetic, logic, load/store, branch instructions
- Memory-mapped I/O support
- Harvard architecture (separate program/data memory)
- Compatible with FPGA synthesis on Xilinx Vivado
- SystemVerilog modules with clean FSM-based design
- Fully modular and extendable (UART, interrupts planned)

---

## 🧠 Architecture Overview

MAK-8 follows a 3-stage pipeline-like operation:

1. **Fetch** – Instruction fetched from ROM via PC
2. **Decode** – Registers and control signals selected
3. **Execute** – ALU ops or memory read/write

### 🔲 Block Diagram (Simplified)
           +-----------------+
           |  Program ROM    |
           +--------+--------+
                    |
             +------+------+
             |  Instruction |
             |    Decoder   |
             +--+-------+---+
                |       |
       +--------+       +----------+
+------+-----+             +-------+------+
| Register    |            |   Control     |
| File (R0–R7)|            |     FSM       |
+------+-----+             +-------+------+
       |                           |
       +-------------+------------+
                     |
                 +---+---+
                 |  ALU  |
                 +---+---+
                     |
               +-----+-----+
               |   Data RAM |
               +-----------+

---

## 🗂️ File Structure

mak-8/
├── LICENSE.txt
├── README.md
├── rtl/
│   ├── mak8_top.sv
│   ├── alu.sv
│   ├── register_file.sv
│   ├── pc.sv
│   ├── control_unit.sv
│   ├── rom.sv
│   └── ram.sv
├── sim/
│   └── testbench.sv
├── doc/
│   └── isa_spec.md
├── constraints/
│   └── nexys_a7.xdc
└── programs/
└── led_blink.hex

---

## 🔋 Getting Started

### 🔧 Prerequisites:
- Xilinx Vivado 2020.2 or later
- Digilent Nexys A7 FPGA board
- Basic SystemVerilog and RTL simulation knowledge


