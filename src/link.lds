OUTPUT_ARCH("riscv")

MEMORY
{
   RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
}

ENTRY(_start)

SECTIONS
{
  . = 0x00000000;
  .init : { *(.init) }
  .text : { *(.text) }
  . = ALIGN(0x400);
  .data : {
    *(.rodata)
    *(.data)
  }
  .bss : { *(.bss) }
  _end = .;
  PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));
}
