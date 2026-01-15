ASM=nasm
SRC_BOOT=boot.asm
SRC_KERN=kernel.asm
BIN_BOOT=boot.bin
BIN_KERN=kernel.bin
IMG=bootloader.img

all: $(IMG)

$(BIN_BOOT): $(SRC_BOOT)
	$(ASM) -f bin $(SRC_BOOT) -o $(BIN_BOOT)

$(BIN_KERN): $(SRC_KERN)
	$(ASM) -f bin $(SRC_KERN) -o $(BIN_KERN)

$(IMG): $(BIN_BOOT) $(BIN_KERN)
	cat $(BIN_BOOT) $(BIN_KERN) > $(IMG)
	truncate -s 1440k $(IMG)

run: $(IMG)
	qemu-system-x86_64 -drive format=raw,file=$(IMG)

clean:
	rm -f $(BIN_BOOT) $(BIN_KERN) $(IMG)
