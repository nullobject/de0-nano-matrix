# DE0-Nano Matrix

A LED matrix controller written in VHDL for the DE0-Nano FPGA development board.

## Getting Started

Install dependencies;

    $ sudo apt install srecord z80asm

Compile the core:

    $ make build

Compile an example program (choose one):

    $ make blink
    $ make leds
    $ make tile

Program the DE0-Nano:

    $ make program
