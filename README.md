# MIPS Verilog CPU
A simple Verilog implementation of a 32-bit MIPS Cpu.

# Requirements
* Icarus Verilog simulator: http://iverilog.icarus.com/
* Java 8 for running the waveform viewer and MARS MIPS simulator
* Make
* Python 3

# Development
* To elaborate the design, run `make`
* To run the top level module listed in the Makefile (TOP variable), use `make run`. This can be changed to run a different testbench file.
* To run a test program, run `make <test_name>` where `test_name` is the name of the MIPS assembly file. For example, run `make test_1` to run test_1.asm.
  * This will assemble the test file using MARS, and run the assembled executable on both the MARS simulator and our design. An text-formatted dump of the registers and data memory is then compared using diff.
* To run the full suite of tests, run `make regression`
* To view a VCD waveform produced by the simulator, run `make waves`.

# Supported Instructions
* lw, sw
* lbu, sb
* beq, bne
* j, jal, jr
* addi, addiu
* slt, sltu
* and, or, nor
* add, addu
* sub, subu
* srl, sll
* syscall (only for terminating program, no exception handling)

# Memory Layout
Our CPU uses roughly the same memory map as MARS run in "CompactDataAtZero" mode.
Note that only the first 12 KB of space are currently used.
The address space is as follows:
* 0x0000-0x0FFF .data segment
* 0x1000-0x1FFF .extern segment (for global pointer)
* 0x2000-0x2FFF stack segment
* 0x3000-0x3FFF .text segment (in reality, separate instruction memory is used by our CPU)
* 0x4000-0x7FFF kernel segment (not modeled by our CPU)

# Credits
Waveform viewer from https://github.com/jbush001/WaveView  
MARS MIPS simulator from http://courses.missouristate.edu/KenVollmar/mars/