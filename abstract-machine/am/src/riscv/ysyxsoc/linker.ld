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
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  } > mrom
  .data : {
    *(.data*)
  } > mrom
  edata = .;
  _data = .;
  .bss : {
	_bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  } > mrom
  . = ORIGIN(sram);
  _heap_start = .;
  _heap_end = _heap_start + 4K;
  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
