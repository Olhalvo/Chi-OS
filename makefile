ASM=nasm
CC=gcc

SRC_DIR=src
TOOLS_DIR=$(SRC_DIR)/tools
BUILD_DIR=build

.PHONY : all floppy_image kernel bootloader clean always tools_fat

all: floppy_image tools_fat

#floppyimg

floppy_image : $(BUILD_DIR)/main_floppy.img 
$(BUILD_DIR)/main_floppy.img : bootloader kernel
	dd if=/dev/zero of=$(BUILD_DIR)/main_floppy.img bs=512 count=2880
	mkfs.fat -F 12 -n "CHIOS" $(BUILD_DIR)/main_floppy.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main_floppy.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main_floppy.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
	mcopy -i $(BUILD_DIR)/main_floppy.img test.txt "::test.txt"

#bootloader
bootloader : $(BUILD_DIR)/bootloader.bin
$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(SRC_DIR)/bootloader/boot.asm -f bin -o $(BUILD_DIR)/bootloader.bin

#kernel
kernel : $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(SRC_DIR)/kernel/main.asm -f bin -o $(BUILD_DIR)/kernel.bin

#always
always :
	mkdir -p $(BUILD_DIR)

#tools_fat
tools_fat: $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c
$(BUILD_DIR)/tools/fat: always 
	mkdir -p $(BUILD_DIR)/tools
	$(CC) -g -o $(BUILD_DIR)/tools/fat $(TOOLS_DIR)/fat/fat.c

#clean
clean :
	rm -rf $(BUILD_DIR)