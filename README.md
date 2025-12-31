# Custom x86 Bootloader

Just a little bootloader I threw together one evening while messing around with low-level stuff again. It's pure NASM assembly, starts in real mode, prints a simple "booting..." message with some dots for drama, enables the A20 line the quick way, then jumps into 32-bit protected mode.

Once it's in protected mode it clears the screen to blue, prints a title and a success message in nice colors, grabs the CPU vendor string with CPUID, and displays that too. After that it just halts forever (no fancy kernel yet).

It's nothing revolutionary, but it's fun to see it run and it actually fits in 512 bytes with room to spare.

### How to build

You'll need NASM:

```bash
nasm -f bin boot.asm -o boot.bin
