# Custom x86 Bootloader

A sophisticated x86 bootloader transition project. It starts in 16-bit Real Mode, switches to 32-bit Protected Mode, and finally enters 64-bit Long Mode.

## Architecture

- **Stage 1 (boot.asm)**: 16-bit bootloader that loads the second stage from disk and performs the initial jump into Protected Mode.
- **Stage 2 (kernel.asm)**: Loads at 0x8000. It verifies CPU capabilities (CPUID, Long Mode), sets up 4-level paging, and switches the processor to 64-bit Long Mode.

## Building

To build the bootloader and create a floppy image:

```bash
make
```

## Running

To run the bootloader in QEMU:

```bash
make run
```
