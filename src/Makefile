CC=riscv64-unknown-elf-gcc
LD=riscv64-unknown-elf-ld
AS=riscv64-unknown-elf-as
OBJCOPY=riscv64-unknown-elf-objcopy

CFLAGS+=-mabi=ilp32 -march=rv32im
CFLAGS+=-Wall -fno-builtin -nostdinc
CFLAGS+=-ffreestanding -nostartfiles -nostdlib -nodefaultlibs

ASFLAGS+=-mabi=ilp32 -march=rv32im

LDFLAGS+=-Map test.map --gc-sections -m elf32lriscv -T

all: test.mif

test: link.lds crt0.o test.o
	$(LD) $(LDFLAGS) $^ -o $@

test.mif : test.bin
	./bin2mif.py -w 32 $< $@

test.bin : test
	$(OBJCOPY) -O binary $< $@

test.txt : test.bin
	hexdump -v -e '/2 "%04x\n"' $< > $@

clean:
	rm test *.bin *.mif *.o *.map
