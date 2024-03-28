.org 0x0
.text
.globl _idt,_gdt,_pg_dir,_tmp_floppy_area
_pg_dir:
.globl startup_32
startup_32:
  call start 
hold_on:
  jmp hold_on
