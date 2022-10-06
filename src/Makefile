CC=riscv64-unknown-elf-gcc
LD=riscv64-unknown-elf-ld
AS=riscv64-unknown-elf-as
OBJCOPY=riscv64-unknown-elf-objcopy

ifeq ($(XLEN), 32)
CFLAGS+=-mabi=ilp32 -march=rv32im
ASFLAGS+=-mabi=ilp32 -march=rv32im
LDFLAGS+=-m elf32lriscv
endif

CFLAGS+=-Wall -fno-builtin -nostdinc
CFLAGS+=-ffreestanding -nostartfiles -nostdlib -nodefaultlibs
LDFLAGS+=-Map test.map --gc-sections -T

OBJS= crt0.o test.o uart.o char.o timer.o

all: test.mif

test.elf: link.lds $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

test.mif : test.bin
	./bin2mif.py -w 32 $< $@

test.bin : test.elf
	$(OBJCOPY) -O binary $< $@

test.txt : test.bin
	hexdump -v -e '/2 "%04x\n"' $< > $@

clean:
	rm *.elf *.bin *.mif *.o *.map
