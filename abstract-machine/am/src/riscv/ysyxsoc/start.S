.section .boot.entry, "ax"
.globl _start
.type _start, @function

_start:
  la sp, _stack_pointer
  call _fsbl
  la t0, _ssbl_entry
  jr t0

.size _start, . - _start

.section .boot.ssbl.entry, "ax"
.globl _ssbl_entry
.type _ssbl_entry, @function

_ssbl_entry:
  la sp, _stack_pointer
  call _ssbl
  la t0, _main
  jr t0

.size _ssbl_entry, . - _ssbl_entry

.section entry, "ax"
.globl _main
.type _main, @function

_main:
  mv s0, zero
  la sp, _stack_pointer
  csrr a0, mvendorid
  csrr a1, marchid
  call _trm_init

.size _main, . - _main
