ENTRY(_start)

MEMORY {
  sram (rwx): ORIGIN = 0x0f000000, LENGTH = 8K
  flash (rx): ORIGIN = 0x30000000, LENGTH = 256M
}

SECTIONS {
  .text : {
    *(entry)
    *(.text*)
  } > flash
  .rodata : {
    *(.rodata*)
  } > flash
  .data : {
  _data_start = .;
    *(.data*)
    *(.sdata*)
  _data_end = .;
  } > sram AT > flash
  _data_load = LOADADDR(.data);
  .bss (NOLOAD) : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  _bss_end = .;
  } > sram
  . = ALIGN(4);
  _heap_start = .;
  _heap_end = _heap_start + 4K;
  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
