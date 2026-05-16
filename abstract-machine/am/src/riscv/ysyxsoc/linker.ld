ENTRY(_start)

MEMORY {
  sram (rwx): ORIGIN = 0x0f000000, LENGTH = 8K
  flash (rx): ORIGIN = 0x30000000, LENGTH = 16M
  psram (rwx):ORIGIN = 0x80000000, LENGTH = 4M
}

SECTIONS {
  .boot.fsbl : {
    *(.boot.entry)
    *(.boot.fsbl*)
  } > flash

  .boot.ssbl : {
    _ssbl_start = .;
    *(.boot.ssbl*)
    _ssbl_end = .;
  } > sram AT > flash
  _ssbl_load = LOADADDR(.boot.ssbl);

  .text : {
    . = ALIGN(4);
    _text_start = .;
    *(entry)
    *(.text*)
    _text_end = .;
  } > psram AT > flash
  _text_load = LOADADDR(.text);

  .rodata : {
    . = ALIGN(4);
    _rodata_start = .;
    *(.rodata*)
    _rodata_end = .;
  } > psram AT > flash
  _rodata_load = LOADADDR(.rodata);

  .data : {
    . = ALIGN(4);
    _data_start = .;
    *(.data*)
    *(.sdata*)
    _data_end = .;
  } > psram AT > flash
  _data_load = LOADADDR(.data);

  .bss (NOLOAD) : {
    . = ALIGN(4);
	  _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
    _bss_end = .;
  } > psram

  . = ALIGN(4);
  _heap_start = .;
  _heap_end = ORIGIN(psram) + LENGTH(psram);
  _stack_pointer = ORIGIN(sram) + LENGTH(sram);
}
