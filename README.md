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

## 🔋 Getting Started

### 🔧 Prerequisites:
- Xilinx Vivado 2020.2 or later
- Digilent Nexys A7 FPGA board
- Basic SystemVerilog and RTL simulation knowledge

---

## ⚙️ Emulation & FPGA Deployment

MAK-8 is written in **SystemVerilog**, simulated using Vivado/ModelSim, and synthesized onto the **Digilent Nexys A7** FPGA board.

### 🧪 Emulation Flow:
- Write assembly → Convert to machine code (HEX)
- Load HEX into ROM (Vivado's init file)
- Simulate in Vivado or ModelSim using `testbench.sv`

### 🔧 FPGA Deployment:
1. Open **Vivado**
2. Create a new project
3. Add all `.sv` files from the `rtl/` folder
4. Set `mak8_top.sv` as the top module
5. Import `nexys_a7.xdc` constraint file
6. Assign pins for:
   - LEDs (for register/memory output)
   - Switches/Buttons (for inputs)
7. Generate Bitstream and Program the FPGA
8. Output can be verified using onboard LEDs, or over UART (future)

💡 **Clock Input**: Use the onboard 100 MHz clock, divided down in SystemVerilog.

---

## 👨‍💻 Author
Manikanta Gonugondla - Btech, BS in Electronics



