ENTRY(_start)

MEMORY {
  mrom (rx) : ORIGIN = 0x20000000, LENGTH = 4K
  sram (rwx): ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
  .text : {
    *(entry)
    *(.text*)
  } > mrom
  .rodata : {
    *(.rodata*)
  } > mrom
  .data : {
  _data_start = .;
    *(.data*)
    *(.sdata*)
  _data_end = .;
  } > sram AT > mrom
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
